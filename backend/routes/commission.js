const express = require('express');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const router = express.Router();

// Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Get commission history for a promoter or admin
router.get('/history', async (req, res) => {
  try {
    const { promoterId, admin } = req.query;
    
    // If neither promoterId nor admin flag is provided, return error
    if (!promoterId && admin !== 'true') {
      return res.status(400).json({
        success: false,
        message: 'Promoter ID is required or admin=true for admin access'
      });
    }

    // Build query for affiliate commissions
    let affiliateQuery = supabase
      .from('affiliate_commissions')
      .select(`
        *,
        customer:customer_id(name, mobile, customer_id),
        initiator:initiator_promoter_id(name, promoter_id),
        recipient:recipient_id(name, promoter_id)
      `)
      .order('created_at', { ascending: false });

    // For specific promoter, filter by recipient
    if (promoterId) {
      affiliateQuery = affiliateQuery.eq('recipient_id', promoterId);
    }

    // Get affiliate commission records
    const { data: affiliateCommissions, error: affiliateError } = await affiliateQuery;

    if (affiliateError) {
      console.error('Error fetching commission history:', affiliateError);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch commission history'
      });
    }

    // Use only affiliate commissions for now (income_transactions table is empty)
    const allCommissions = (affiliateCommissions || []).map(commission => ({
      ...commission,
      commission_type: 'affiliate'
    }));

    // Calculate totals
    const totals = allCommissions.reduce((acc, commission) => {
      if (commission.status === 'credited' || commission.status === 'completed') {
        acc.totalEarned += commission.amount;
        acc.totalCount += 1;
        
        // Separate totals by type
        if (commission.commission_type === 'affiliate') {
          acc.affiliateEarned += commission.amount;
          acc.affiliateCount += 1;
        } else if (commission.commission_type === 'repayment') {
          acc.repaymentEarned += commission.amount;
          acc.repaymentCount += 1;
        }
      }
      return acc;
    }, { 
      totalEarned: 0, 
      totalCount: 0,
      affiliateEarned: 0,
      affiliateCount: 0,
      repaymentEarned: 0,
      repaymentCount: 0
    });

    res.json({
      success: true,
      data: allCommissions,
      totals
    });
  } catch (error) {
    console.error('Error in commission history:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get wallet balance for a promoter
router.get('/wallet', async (req, res) => {
  try {
    const { promoterId } = req.query;
    
    if (!promoterId) {
      return res.status(400).json({
        success: false,
        message: 'Promoter ID is required'
      });
    }

    // Calculate wallet balance including both affiliate and repayment commissions
    let totalEarned = 0;
    let affiliateEarned = 0;
    let repaymentEarned = 0;
    let totalWithdrawn = 0;
    let availableBalance = 0;

    try {
      // Get affiliate commissions
      const { data: affiliateCommissions } = await supabase
        .from('affiliate_commissions')
        .select('amount, status')
        .eq('recipient_id', promoterId)
        .eq('status', 'credited');

      affiliateEarned = affiliateCommissions?.reduce((sum, c) => sum + parseFloat(c.amount), 0) || 0;

      // Skip repayment commissions table as it doesn't exist
      repaymentEarned = 0;

      totalEarned = affiliateEarned + repaymentEarned;

      // Get withdrawals
      const { data: withdrawals } = await supabase
        .from('withdrawal_requests')
        .select('amount, status')
        .eq('promoter_id', promoterId)
        .eq('status', 'approved');

      totalWithdrawn = withdrawals?.reduce((sum, w) => sum + parseFloat(w.amount), 0) || 0;
      availableBalance = totalEarned - totalWithdrawn;

    } catch (error) {
      console.error('Error calculating wallet balance:', error);
    }

    res.json({
      success: true,
      data: {
        totalEarned,
        affiliateEarned,
        repaymentEarned,
        totalWithdrawn,
        availableBalance,
        pendingWithdrawals: 0
      }
    });
  } catch (error) {
    console.error('Error in wallet balance:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Get withdrawal requests for a promoter
router.get('/withdrawals', async (req, res) => {
  try {
    const { promoterId } = req.query;
    
    if (!promoterId) {
      return res.status(400).json({
        success: false,
        message: 'Promoter ID is required'
      });
    }

    const { data: withdrawals, error } = await supabase
      .from('withdrawal_requests')
      .select('*')
      .eq('promoter_id', promoterId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching withdrawals:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch withdrawals'
      });
    }

    res.json({
      success: true,
      data: withdrawals || []
    });
  } catch (error) {
    console.error('Error in withdrawals:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;
