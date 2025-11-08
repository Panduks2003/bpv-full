import { supabase } from './supabaseClient';

const pinTransactionService = {
  /**
   * Get all pin transactions
   * @returns {Promise<Array>} Array of pin transactions
   */
  getAllPinTransactions: async () => {
    try {
      const { data, error } = await supabase
        .from('pin_transactions')
        .select('*')
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error('Error fetching pin transactions:', error);
      throw error;
    }
  },

  /**
   * Get pin transactions for a specific customer
   * @param {string} customerId - The customer ID
   * @returns {Promise<Array>} Array of pin transactions for the customer
   */
  getCustomerPinTransactions: async (customerId) => {
    try {
      const { data, error } = await supabase
        .from('pin_transactions')
        .select('*')
        .eq('customer_id', customerId)
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      return data || [];
    } catch (error) {
      console.error(`Error fetching pin transactions for customer ${customerId}:`, error);
      throw error;
    }
  },

  /**
   * Create a new pin transaction
   * @param {Object} transaction - The transaction data
   * @returns {Promise<Object>} The created transaction
   */
  createPinTransaction: async (transaction) => {
    try {
      const { data, error } = await supabase
        .from('pin_transactions')
        .insert([transaction])
        .select();
      
      if (error) throw error;
      return data?.[0];
    } catch (error) {
      console.error('Error creating pin transaction:', error);
      throw error;
    }
  },

  /**
   * Update a pin transaction
   * @param {string} id - The transaction ID
   * @param {Object} updates - The fields to update
   * @returns {Promise<Object>} The updated transaction
   */
  updatePinTransaction: async (id, updates) => {
    try {
      const { data, error } = await supabase
        .from('pin_transactions')
        .update(updates)
        .eq('id', id)
        .select();
      
      if (error) throw error;
      return data?.[0];
    } catch (error) {
      console.error(`Error updating pin transaction ${id}:`, error);
      throw error;
    }
  },

  /**
   * Delete a pin transaction
   * @param {string} id - The transaction ID
   * @returns {Promise<void>}
   */
  deletePinTransaction: async (id) => {
    try {
      const { error } = await supabase
        .from('pin_transactions')
        .delete()
        .eq('id', id);
      
      if (error) throw error;
    } catch (error) {
      console.error(`Error deleting pin transaction ${id}:`, error);
      throw error;
    }
  },

  /**
   * Deduct a PIN from a promoter for customer creation
   * @param {string} promoterId - The promoter ID
   * @param {string} customerId - The customer ID (MUST NOT be null)
   * @param {string} customerName - The customer name
   * @returns {Promise<Object>} Result of the operation
   */
  deductPinForCustomerCreation: async (promoterId, customerId, customerName) => {
    try {
      console.log('📌 PIN Deduction - Input values:', { promoterId, customerId, customerName });
      
      if (!promoterId) {
        console.error('❌ Promoter ID is missing for PIN deduction');
        return { success: false, error: 'Promoter ID is required' };
      }
      
      if (!customerId) {
        console.error('❌ Customer ID is missing for PIN deduction');
        return { success: false, error: 'Customer ID is required' };
      }

      // First, deduct the PIN from the promoter
      const { data: updateData, error: updateError } = await supabase.rpc('deduct_promoter_pin', {
        promoter_id: promoterId,
        pins_to_deduct: 1
      });

      if (updateError) {
        console.error('❌ Failed to deduct PIN:', updateError);
        return { success: false, error: updateError.message };
      }
      
      console.log('✅ PIN deduction successful:', updateData);

      // Then, record the transaction
      const transaction = {
        promoter_id: promoterId,
        customer_id: customerId, // Ensure this is not null
        transaction_type: 'deduction',
        pins_count: 1,
        description: `PIN used for customer creation: ${customerName || 'New Customer'}`
      };
      
      console.log('📝 Recording PIN transaction:', transaction);

      const { data: transactionData, error: transactionError } = await supabase
        .from('pin_transactions')
        .insert([transaction])
        .select();

      if (transactionError) {
        console.error('❌ Failed to record PIN transaction:', transactionError);
        return { success: false, error: transactionError.message };
      }
      
      console.log('✅ PIN transaction recorded successfully');

      return { success: true, data: transactionData?.[0] };
    } catch (error) {
      console.error('❌ Error in deductPinForCustomerCreation:', error);
      return { success: false, error: error.message };
    }
  }
};

export default pinTransactionService;