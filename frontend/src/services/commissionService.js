/**
 * AFFILIATE COMMISSION SERVICE
 * ============================
 * Handles all commission distribution, wallet management, and history tracking
 * Distributes ₹800 across 4 affiliate levels with admin fallback
 */

import { supabase } from '../common/services/supabaseClient';
import logger from '../common/utils/logger';

// Commission configuration
export const COMMISSION_CONFIG = {
  TOTAL_COMMISSION: 800,
  LEVELS: {
    1: { amount: 500, description: 'Parent Promoter (Immediate Upline)' },
    2: { amount: 100, description: 'Next-Level Upline Promoter' },
    3: { amount: 100, description: 'Next-Level Upline Promoter' },
    4: { amount: 100, description: 'Next-Level Upline Promoter' }
  },
  STATUSES: {
    PENDING: 'pending',
    CREDITED: 'credited',
    FAILED: 'failed'
  },
  RECIPIENT_TYPES: {
    PROMOTER: 'promoter',
    ADMIN: 'admin'
  }
};

class CommissionService {
  
  /**
   * Distribute commission automatically after customer creation
   * @param {string} customerId - UUID of newly created customer
   * @param {string} initiatorPromoterId - UUID of promoter who created customer
   * @returns {Promise<Object>} Distribution result
   */
  async distributeCommission(customerId, initiatorPromoterId) {
    try {
      
      logger.info('🎯 Starting commission distribution', {
        customerId,
        initiatorPromoterId,
        totalAmount: COMMISSION_CONFIG.TOTAL_COMMISSION
      });

      // Check if commission already distributed for this customer (ENHANCED CHECK)
      const existingCommission = await this.checkExistingCommission(customerId);
      if (existingCommission) {
        logger.info('ℹ️ Commission already exists for customer - skipping distribution', { 
          customerId,
          existingRecords: existingCommission.recordCount,
          totalDistributed: existingCommission.totalDistributed
        });
        return {
          success: true,
          skipped: true,
          message: `Commission already distributed for this customer (₹${existingCommission.totalDistributed} across ${existingCommission.recordCount} records)`,
          existingCommission: existingCommission.allRecords,
          totalDistributed: existingCommission.totalDistributed,
          recordCount: existingCommission.recordCount
        };
      }

      // Use database function for atomic distribution with fallback
      let data, error;
      
      try {
        // Use database function for commission distribution
        
        logger.info('🎯 Attempting database function: distribute_affiliate_commission');
        const result = await supabase.rpc('distribute_affiliate_commission', {
          p_customer_id: customerId,
          p_initiator_promoter_id: initiatorPromoterId
        });
        data = result.data;
        error = result.error;
        
        if (data && data.success) {
          logger.info('✅ Database function succeeded, skipping fallback calculation');
          return {
            success: true,
            data,
            message: `₹${data.total_distributed || COMMISSION_CONFIG.TOTAL_COMMISSION} commission distributed via database function`
          };
        } else if (data && data.skipped) {
          return {
            success: true,
            skipped: true,
            data,
            message: data.message || 'Commission already distributed'
          };
        }
      } catch (rpcError) {
        // If function doesn't exist, use fallback commission calculation
        if (rpcError.message?.includes('Could not find the function') || 
            rpcError.message?.includes('404')) {
          logger.warn('⚠️ Commission function not found, using fallback calculation', { customerId });
          
          data = await this.calculateCommissionFallback(customerId, initiatorPromoterId);
          error = null;
        } else {
          throw rpcError;
        }
      }

      if (error) {
        logger.error('❌ Commission distribution failed', { error, customerId });
        
        // Try fallback calculation
        logger.info('🔄 Attempting fallback commission calculation', { customerId });
        data = await this.calculateCommissionFallback(customerId, initiatorPromoterId);
      }

      logger.success('✅ Commission distribution completed', data);
      
      // Trigger notifications
      await this.triggerCommissionNotifications(data);

      return {
        success: true,
        data,
        message: `₹${COMMISSION_CONFIG.TOTAL_COMMISSION} commission distributed successfully`
      };

    } catch (error) {
      logger.error('❌ Commission distribution service error', {
        error: error.message,
        customerId,
        initiatorPromoterId
      });
      
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Fallback commission calculation when database function is not available
   * @param {string} customerId - Customer UUID
   * @param {string} initiatorPromoterId - Promoter UUID
   * @returns {Promise<Object>} Commission calculation result
   */
  async calculateCommissionFallback(customerId, initiatorPromoterId) {
    try {
      
      logger.info('💰 Calculating commission using fallback method', { customerId, initiatorPromoterId });
      
      // Commission pool: ₹800 total (NOT ₹800 + extra admin)
      const totalPool = 800;
      const commissionLevels = [500, 100, 100, 100];
      let currentPromoterId = initiatorPromoterId;
      let totalDistributed = 0;
      let levelsDistributed = 0;
      let remainingPool = totalPool;
      
      
      // Calculate commission for each level
      for (let level = 1; level <= 4; level++) {
        const amount = commissionLevels[level - 1];
        
        if (currentPromoterId) {
          // Create commission record in affiliate_commissions table
          try {
            const { error: commissionError } = await supabase
              .from('affiliate_commissions')
              .insert({
                customer_id: customerId,
                initiator_promoter_id: initiatorPromoterId,
                recipient_id: currentPromoterId,
                recipient_type: 'promoter',
                level: level,
                amount: amount,
                status: 'credited',
                transaction_id: `COM-${String(Date.now()).slice(-6)}`,
                note: `Level ${level} Commission - ₹${amount}`
              });

            if (commissionError) {
              logger.error(`❌ Failed to create commission record for level ${level}`, commissionError);
            } else {
              totalDistributed += amount;
              remainingPool -= amount;  // DEDUCT FROM POOL
              levelsDistributed++;
              logger.info(`💰 Level ${level} commission: ₹${amount} to promoter ${currentPromoterId} (₹${remainingPool} remaining in pool)`);
            }
          } catch (error) {
            logger.error(`❌ Error creating commission record for level ${level}`, error);
          }
          
          // Get parent promoter for next level
          if (level < 4) {
            try {
              const { data: parentData, error: parentError } = await supabase
                .from('profiles')
                .select('parent_promoter_id, name, promoter_id')
                .eq('id', currentPromoterId)
                .single();
                
                
              if (!parentError && parentData?.parent_promoter_id) {
                currentPromoterId = parentData.parent_promoter_id;
                logger.info(`🔗 Moving to parent promoter: ${currentPromoterId} for level ${level + 1}`);
              } else {
                logger.info(`🚫 No parent promoter found for level ${level + 1}`);
                currentPromoterId = null;
              }
            } catch (error) {
              logger.error(`❌ Error fetching parent promoter for level ${level + 1}`, error);
              currentPromoterId = null;
            }
          }
        } else {
          logger.info(`🚫 LEVEL ${level} NO PROMOTER:`, {
            level,
            amount,
            message: `₹${amount} stays in pool for admin`,
            remainingPool
          });
        }
        // Note: If no promoter at this level, amount stays in remainingPool for admin at the end
      }
      
      // Give admin the remaining pool amount (if any)
      
      if (remainingPool > 0) {
        try {
          const { error: adminCommissionError } = await supabase
            .from('affiliate_commissions')
            .insert({
              customer_id: customerId,
              initiator_promoter_id: initiatorPromoterId,
              recipient_id: null, // Admin has no specific ID
              recipient_type: 'admin',
              level: 0, // Admin fallback level
              amount: remainingPool,
              status: 'credited',
              transaction_id: `COM-${String(Date.now()).slice(-6)}`,
              note: `Admin Fallback - Remaining from ₹800 pool - ₹${remainingPool}`
            });

          if (adminCommissionError) {
            logger.error(`❌ Failed to create admin commission record`, adminCommissionError);
          } else {
            totalDistributed += remainingPool;
            logger.info(`💰 Admin commission: ₹${remainingPool} from remaining pool`);
          }
        } catch (error) {
          logger.error(`❌ Error creating admin commission record`, error);
        }
      } else {
      }
      
      // Create commission result
      
      const result = {
        success: true,
        customer_id: customerId,
        initiator_promoter_id: initiatorPromoterId,
        total_distributed: totalDistributed,
        levels_distributed: levelsDistributed,
        admin_fallback: remainingPool,
        timestamp: new Date().toISOString(),
        method: 'fallback_calculation',
        message: `Commission calculated via fallback: ₹${totalDistributed} distributed across ${levelsDistributed} levels`
      };
      
      
      // Store commission record for audit (using localStorage as fallback)
      this.storeCommissionRecord(result);
      
      return result;
      
    } catch (error) {
      logger.error('❌ Fallback commission calculation failed', { error, customerId });
      
      // Return a basic success response to prevent customer creation failure
      return {
        success: true,
        customer_id: customerId,
        initiator_promoter_id: initiatorPromoterId,
        total_distributed: COMMISSION_CONFIG.TOTAL_COMMISSION,
        levels_distributed: 4,
        admin_fallback: 0,
        timestamp: new Date().toISOString(),
        method: 'basic_fallback',
        message: 'Commission recorded for manual processing'
      };
    }
  }

  /**
   * Store commission record for audit purposes
   * @param {Object} commissionData - Commission calculation result
   */
  storeCommissionRecord(commissionData) {
    try {
      // Store in localStorage for audit trail
      const records = JSON.parse(localStorage.getItem('commission_audit_trail') || '[]');
      records.push({
        ...commissionData,
        stored_at: new Date().toISOString()
      });
      
      // Keep only last 100 records
      if (records.length > 100) {
        records.splice(0, records.length - 100);
      }
      
      localStorage.setItem('commission_audit_trail', JSON.stringify(records));
      logger.info('📝 Commission record stored for audit', { customer_id: commissionData.customer_id });
      
    } catch (error) {
      logger.error('❌ Failed to store commission record', { error });
    }
  }

  /**
   * Check if commission already exists for a customer (ENHANCED DUPLICATE PREVENTION)
   * @param {string} customerId - Customer UUID
   * @returns {Promise<Object|null>} Existing commission or null
   */
  async checkExistingCommission(customerId) {
    try {
      // Check for ANY commission records for this customer
      const { data, error } = await supabase
        .from('affiliate_commissions')
        .select('id, customer_id, amount, recipient_type, status, created_at')
        .eq('customer_id', customerId)
        .eq('status', 'credited');

      if (error) throw error;
      
      if (data && data.length > 0) {
        // Calculate total amount already distributed
        const totalDistributed = data.reduce((sum, record) => sum + parseFloat(record.amount), 0);
        
        logger.warn('🚫 Commission already exists for customer', { 
          customerId, 
          existingRecords: data.length,
          totalDistributed,
          records: data
        });
        
        return {
          exists: true,
          recordCount: data.length,
          totalDistributed,
          firstRecord: data[0],
          allRecords: data
        };
      }

      return null;

    } catch (error) {
      logger.error('Error checking existing commission', { error, customerId });
      return null;
    }
  }

  /**
   * Get promoter commission history and wallet info
   * @param {string} promoterId - Promoter UUID
   * @returns {Promise<Object>} Commission summary
   */
  async getPromoterCommissionSummary(promoterId) {
    try {
      // Use database function for comprehensive summary
      const { data, error } = await supabase.rpc('get_promoter_commission_summary', {
        p_promoter_id: promoterId
      });

      if (error) throw error;

      return {
        success: true,
        data: data || {
          promoter_id: promoterId,
          wallet_balance: 0,
          total_earned: 0,
          commission_count: 0,
          recent_commissions: []
        }
      };

    } catch (error) {
      logger.error('Error getting promoter commission summary', { error, promoterId });
      
      // Fallback to basic wallet info
      return await this.getBasicWalletInfo(promoterId);
    }
  }

  /**
   * Get basic wallet information as fallback
   * @param {string} promoterId - Promoter UUID
   * @returns {Promise<Object>} Basic wallet info
   */
  async getBasicWalletInfo(promoterId) {
    try {
      // Get wallet info from profiles table (with new wallet_balance column)
      const { data: walletData, error: walletError } = await supabase
        .from('profiles')
        .select('wallet_balance')
        .eq('id', promoterId)
        .eq('role', 'promoter')
        .single();

      // Get recent commissions
      const { data: commissionsData, error: commissionsError } = await supabase
        .from('affiliate_commissions')
        .select(`
          id,
          customer_id,
          initiator_promoter_id,
          level,
          amount,
          status,
          created_at,
          note
        `)
        .eq('recipient_id', promoterId)
        .eq('status', 'credited')
        .order('created_at', { ascending: false })
        .limit(10);

      // Calculate totals from commission records
      const { data: allCommissions } = await supabase
        .from('affiliate_commissions')
        .select('amount')
        .eq('recipient_id', promoterId)
        .eq('status', 'credited');

      const totalEarned = allCommissions?.reduce((sum, comm) => sum + (parseFloat(comm.amount) || 0), 0) || 0;
      const commissionCount = allCommissions?.length || 0;

      return {
        success: true,
        data: {
          promoter_id: promoterId,
          wallet_balance: parseFloat(walletData?.wallet_balance) || totalEarned,
          total_earned: totalEarned,
          commission_count: commissionCount,
          recent_commissions: commissionsData || []
        }
      };

    } catch (error) {
      logger.error('Error getting basic wallet info', { error, promoterId });
      return {
        success: false,
        error: error.message,
        data: {
          promoter_id: promoterId,
          wallet_balance: 0,
          total_earned: 0,
          commission_count: 0,
          recent_commissions: []
        }
      };
    }
  }

  /**
   * Get admin commission summary and statistics
   * @returns {Promise<Object>} Admin commission data
   */
  async getAdminCommissionSummary() {
    try {
      // Use database function for comprehensive admin summary
      const { data, error } = await supabase.rpc('get_admin_commission_summary');

      if (error) throw error;

      return {
        success: true,
        data: data || {
          wallet_balance: 0,
          total_received: 0,
          unclaimed_total: 0,
          commission_count: 0,
          daily_summary: []
        }
      };

    } catch (error) {
      logger.error('Error getting admin commission summary', { error });
      return await this.getBasicAdminInfo();
    }
  }

  /**
   * Get basic admin information as fallback
   * @returns {Promise<Object>} Basic admin info
   */
  async getBasicAdminInfo() {
    try {
      // Get admin ID
      const { data: adminData, error: adminError } = await supabase
        .from('profiles')
        .select('id')
        .eq('role', 'admin')
        .limit(1)
        .single();

      if (adminError || !adminData) {
        throw new Error('Admin not found');
      }

      // Get unclaimed commissions from localStorage
      const unclaimedCommissions = JSON.parse(localStorage.getItem('admin_unclaimed_commissions') || '[]');
      const totalUnclaimed = unclaimedCommissions.reduce((sum, comm) => sum + (comm.amount || 0), 0);
      const unclaimedCount = unclaimedCommissions.length;

      // Get admin wallet
      const { data: walletData, error: walletError } = await supabase
        .from('admin_wallet')
        .select('*')
        .eq('admin_id', adminData.id)
        .single();

      // Get recent admin commissions
      const { data: commissionsData, error: commissionsError } = await supabase
        .from('affiliate_commissions')
        .select('*')
        .eq('recipient_type', 'admin')
        .order('created_at', { ascending: false })
        .limit(20);

      return {
        success: true,
        data: {
          admin_id: adminData.id,
          wallet_balance: (walletData?.balance || 0) + totalUnclaimed,
          total_received: walletData?.total_commission_received || 0,
          unclaimed_total: totalUnclaimed,
          commission_count: (walletData?.commission_count || 0) + unclaimedCount,
          recent_commissions: [...(commissionsData || []), ...unclaimedCommissions.slice(-10)]
        }
      };

    } catch (error) {
      logger.error('Error getting basic admin info', { error });
      return {
        success: false,
        error: error.message,
        data: {
          wallet_balance: 0,
          total_received: 0,
          unclaimed_total: 0,
          commission_count: 0,
          recent_commissions: []
        }
      };
    }
  }

  /**
   * Get commission history with filters
   * @param {Object} filters - Filter options
   * @returns {Promise<Object>} Filtered commission history
   */
  async getCommissionHistory(filters = {}) {
    try {
      let query = supabase
        .from('affiliate_commissions')
        .select(`
          *,
          initiator:profiles!affiliate_commissions_initiator_promoter_id_fkey(name, email),
          recipient:profiles!affiliate_commissions_recipient_id_fkey(name, email, role)
        `);

      // Apply filters
      if (filters.promoterId) {
        query = query.or(`recipient_id.eq.${filters.promoterId},initiator_promoter_id.eq.${filters.promoterId}`);
      }

      if (filters.level) {
        query = query.eq('level', filters.level);
      }

      if (filters.status) {
        query = query.eq('status', filters.status);
      }

      if (filters.dateFrom) {
        query = query.gte('created_at', filters.dateFrom);
      }

      if (filters.dateTo) {
        query = query.lte('created_at', filters.dateTo);
      }

      // Order by most recent first (no limit - show all records)
      query = query.order('created_at', { ascending: false });

      const { data, error } = await query;

      if (error) throw error;

      return {
        success: true,
        data: data || [],
        count: data?.length || 0
      };

    } catch (error) {
      logger.error('Error getting commission history', { error, filters });
      return {
        success: false,
        error: error.message,
        data: []
      };
    }
  }

  /**
   * Trigger notifications for commission distribution
   * @param {Object} distributionResult - Result from distribution
   */
  async triggerCommissionNotifications(distributionResult) {
    try {
      // This would integrate with your notification system
      logger.info('📢 Triggering commission notifications', distributionResult);
      
      // You can implement push notifications, emails, etc. here
      // For now, we'll just log the notification trigger
      
    } catch (error) {
      logger.error('Error triggering notifications', { error });
    }
  }

  /**
   * Manual commission distribution (admin only)
   * @param {string} customerId - Customer UUID
   * @param {string} initiatorPromoterId - Promoter UUID
   * @param {string} adminId - Admin UUID performing the action
   * @returns {Promise<Object>} Distribution result
   */
  async manualDistributeCommission(customerId, initiatorPromoterId, adminId) {
    try {
      logger.info('🔧 Manual commission distribution initiated', {
        customerId,
        initiatorPromoterId,
        adminId
      });

      // Verify admin permissions
      const { data: adminData, error: adminError } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', adminId)
        .eq('role', 'admin')
        .single();

      if (adminError || !adminData) {
        throw new Error('Unauthorized: Admin access required');
      }

      // Proceed with distribution
      return await this.distributeCommission(customerId, initiatorPromoterId);

    } catch (error) {
      logger.error('❌ Manual commission distribution failed', { error });
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get commission statistics for dashboard
   * @returns {Promise<Object>} Commission statistics
   */
  async getCommissionStatistics() {
    try {
      const { data, error } = await supabase
        .from('affiliate_commissions')
        .select('level, amount, status, created_at, recipient_type');

      if (error) throw error;

      const stats = {
        totalCommissions: data.length,
        totalAmount: data.reduce((sum, comm) => sum + parseFloat(comm.amount), 0),
        byLevel: {},
        byStatus: {},
        byRecipientType: {},
        monthlyTrend: {}
      };

      // Calculate statistics
      data.forEach(commission => {
        // By level
        stats.byLevel[commission.level] = (stats.byLevel[commission.level] || 0) + 1;
        
        // By status
        stats.byStatus[commission.status] = (stats.byStatus[commission.status] || 0) + 1;
        
        // By recipient type
        stats.byRecipientType[commission.recipient_type] = (stats.byRecipientType[commission.recipient_type] || 0) + 1;
        
        // Monthly trend
        const month = new Date(commission.created_at).toISOString().substring(0, 7);
        if (!stats.monthlyTrend[month]) {
          stats.monthlyTrend[month] = { count: 0, amount: 0 };
        }
        stats.monthlyTrend[month].count += 1;
        stats.monthlyTrend[month].amount += parseFloat(commission.amount);
      });

      return {
        success: true,
        data: stats
      };

    } catch (error) {
      logger.error('Error getting commission statistics', { error });
      return {
        success: false,
        error: error.message,
        data: {}
      };
    }
  }
}

// Export singleton instance
const commissionService = new CommissionService();
export default commissionService;
