import React, { useState, useEffect } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import { useUnifiedToast } from "../../common/services/unifiedToastService";
import AdminNavbar from '../components/AdminNavbar';
import UnifiedCustomerForm from '../../common/components/UnifiedCustomerForm';
import PaymentManager from '../../common/components/PaymentManager';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { supabase } from "../../common/services/supabaseClient";
import pinTransactionService from '../../common/services/pinTransactionService';
import commissionService from '../../services/commissionService';
import { Search, Plus, Edit, Trash2, Users, Mail, Phone, CreditCard } from 'lucide-react';
import { SkeletonTable } from '../components/skeletons';

function AdminCustomers() {
  const { user } = useAuth();
  const { showSuccess, showError } = useUnifiedToast();
  useScrollAnimation();

  // State management
  const [customers, setCustomers] = useState([]);
  const [promoters, setPromoters] = useState([]);
  const [filteredCustomers, setFilteredCustomers] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [editingCustomer, setEditingCustomer] = useState(null);
  const [deletingCustomer, setDeletingCustomer] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showPaymentManager, setShowPaymentManager] = useState(false);
  const [selectedCustomerForPayments, setSelectedCustomerForPayments] = useState(null);

  // Load data on component mount
  useEffect(() => {
    loadCustomers();
    loadPromoters();
  }, []);

  // Filter and search logic
  useEffect(() => {
    let filtered = customers || [];

    // Search filter
    if (searchTerm) {
      filtered = filtered.filter(customer => {
        const name = (customer?.name || '').toLowerCase();
        const email = (customer?.email || '').toLowerCase();
        const phone = (customer?.phone || '').toLowerCase();
        const customerId = (customer?.customer_id || '').toLowerCase();
        const searchLower = (searchTerm || '').toLowerCase();
        return name.includes(searchLower) || 
               email.includes(searchLower) || 
               phone.includes(searchLower) ||
               customerId.includes(searchLower);
      });
    }

    // Status filter
    if (statusFilter) {
      filtered = filtered.filter(customer => {
        const customerStatus = (customer?.status || 'active').toLowerCase();
        return customerStatus === statusFilter.toLowerCase();
      });
    }

    setFilteredCustomers(filtered);
  }, [customers, searchTerm, statusFilter]);

  // Load customers from Supabase - using direct profiles query for consistency
  const loadCustomers = async () => {
    try {
      setLoading(true);
      
      const { data, error } = await supabase
        .from('profiles')
        .select(`
          id,
          name,
          email,
          phone,
          customer_id,
          state,
          city,
          pincode,
          address,
          saving_plan,
          parent_promoter_id,
          status,
          created_at,
          updated_at
        `)
        .eq('role', 'customer')
        .order('created_at', { ascending: false });
      
      if (error) {
        setCustomers([]);
        setFilteredCustomers([]);
        throw error;
      }
      
      setCustomers(data || []);
      setFilteredCustomers(data || []);
    } catch (error) {
      setCustomers([]);
      setFilteredCustomers([]);
    } finally {
      setLoading(false);
    }
  };

  // Load promoters for dropdown - using direct supabase query for consistency
  const loadPromoters = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, name, email, promoter_id, created_at')
        .eq('role', 'promoter')
        .order('created_at', { ascending: false });
        
      if (error) {
        throw error;
      }
      
      setPromoters(data || []);
    } catch (error) {
      setPromoters([]);
    }
  };

  // Get available promoters for dropdown
  const getAllAvailableParents = () => {
    return promoters || [];
  };

  // Form validation is now handled by UnifiedCustomerForm

  // Modal handlers
  const openCreateModal = () => {
    setEditingCustomer(null);
    setShowModal(true);
  };

  const openEditModal = (customer) => {
    setEditingCustomer(customer);
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingCustomer(null);
  };

  const openDeleteModal = (customer) => {
    setDeletingCustomer(customer);
    setShowDeleteModal(true);
  };

  const closeDeleteModal = () => {
    setShowDeleteModal(false);
    setDeletingCustomer(null);
  };

  // Payment management handlers
  const openPaymentManager = (customer) => {
    setSelectedCustomerForPayments(customer);
    setShowPaymentManager(true);
  };

  const closePaymentManager = () => {
    setShowPaymentManager(false);
    setSelectedCustomerForPayments(null);
  };


  // Toggle customer status - using direct supabase update
  const toggleCustomerStatus = async (customer) => {
    try {
      const currentStatus = customer.status || 'active';
      const newStatus = currentStatus === 'active' ? 'inactive' : 'active';
      
      const { error } = await supabase
        .from('profiles')
        .update({ status: newStatus })
        .eq('id', customer.id);
      
      if (error) throw error;
      
      showSuccess(`Customer status updated successfully.\n\n${customer.name} is now ${newStatus}.`);
      // Reload customers to reflect changes
      await loadCustomers();
    } catch (error) {
      showError('Failed to update customer status. Please try again.');
    }
  };

  // Handle customer form submission
  const handleCustomerSubmit = async (formData) => {
    try {
      if (editingCustomer) {
        // Update existing customer - use direct Supabase update
        
        const { error } = await supabase
          .from('profiles')
          .update({
            savingPlan: formData.savingPlan || '₹1000 per month for 20 months',
            phone: formData.mobile,
            email: formData.email || null,
            state: formData.state,
            city: formData.city,
            pincode: formData.pincode,
            address: formData.address,
            // parent_promoter_id: formData.parentPromoter, // Removed to preserve hierarchy
            updated_at: new Date().toISOString()
          })
          .eq('id', editingCustomer.id);
        
        if (error) {
          throw error;
        }
        
        showSuccess(`Customer updated successfully.\n\n${formData.name}'s information has been saved.`);
        
        // Reload customers to reflect changes
        await loadCustomers();
        closeModal();
      } else {
        // Create new customer with enhanced validation
        if (!formData.name?.trim() || !formData.mobile?.trim() || !formData.cardNo?.trim()) {
          throw new Error('Missing required fields: name, mobile, and customer ID are mandatory');
        }
        
        // Additional client-side validation
        if (!/^[6-9]\d{9}$/.test(formData.mobile.trim())) {
          throw new Error('Invalid mobile number format');
        }
        
        if (!/^[A-Z0-9]{3,20}$/i.test(formData.cardNo.trim())) {
          throw new Error('Card No must be 3-20 alphanumeric characters');
        }
        
        if (!formData.password || formData.password.length < 6) {
          throw new Error('Password must be at least 6 characters long');
        }
        
        if (!/^\d{6}$/.test(formData.pincode?.trim() || '')) {
          throw new Error('Pincode must be exactly 6 digits');
        }
        
        const dbParams = {
          p_name: formData.name.trim(),
          p_mobile: formData.mobile.trim(),
          p_state: formData.state?.trim() || '',
          p_city: formData.city?.trim() || '',
          p_pincode: formData.pincode?.trim() || '',
          p_address: formData.address?.trim() || '',
          p_customer_id: formData.cardNo.trim().toUpperCase(),
          p_password: formData.password,
          p_parent_promoter_id: formData.parentPromoter,
          p_email: formData.email?.trim() || null
        };
        
        // Check if selected promoter has sufficient pins
        const { data: promoterData, error: promoterError } = await supabase
          .from('profiles')
          .select('pins, name')
          .eq('id', formData.parentPromoter)
          .eq('role', 'promoter')
          .single();
        
        if (promoterError) {
          throw new Error('Failed to verify promoter pin availability');
        }
        
        const promoterPins = promoterData?.pins || 0;
        if (promoterPins < 1) {
          throw new Error(`Selected promoter "${promoterData?.name}" has insufficient pins (${promoterPins} available). Please allocate pins to the promoter first.`);
        }
        
        // Create customer record first
        const { data: customerResult, error: customerError } = await supabase.rpc('create_customer_final', dbParams);
        
        if (customerError || !customerResult?.success) {
          const errorMessage = customerResult?.error || customerError?.message || 'Failed to create customer';
          
          // Handle specific error types with user-friendly messages
          if (errorMessage.includes('Insufficient pins')) {
            throw new Error('The selected promoter does not have enough PINs to create a new customer. Please allocate more PINs to the promoter first.');
          } else if (errorMessage.includes('Promoter not found')) {
            throw new Error('The selected promoter was not found. Please select a valid promoter.');
          } else {
            throw new Error(errorMessage);
          }
        }
        
        // Deduct PIN from promoter using unified service
        const pinResult = await pinTransactionService.deductPinForCustomerCreation(
          formData.parentPromoter,
          customerResult.customer_id,
          formData.name
        );
        
        if (!pinResult.success) {
          // If PIN deduction fails, we should ideally rollback customer creation
          // For now, log the error but continue
          throw new Error(`Customer created but PIN deduction failed: ${pinResult.error}`);
        }
        
        // Ensure customer_id is available before proceeding
        if (!customerResult || !customerResult.customer_id) {
          throw new Error('Customer created but missing customer ID for commission distribution');
        }
        
        // Extract customer_id from result and ensure it's a valid UUID
        const customerId = customerResult.customer_id;
        if (typeof customerId !== 'string' || customerId.trim() === '') {
          throw new Error('Invalid customer ID format');
        }
        
        const commissionResult = await commissionService.distributeCommission(
          customerId, // Validated UUID of newly created customer
          formData.parentPromoter // Selected promoter as initiator
        );
        
        // Commission distribution handled silently
        
        // Create beautiful success message like promoter creation
        showSuccess(
          `Customer created successfully and is ready to use.\n\nCard No: ${formData.cardNo}\nName: ${formData.name}\nLogin: Use Card No + Password`
        );
        
        // Reload customers after creation
        await loadCustomers();
        
        closeModal();
      }

    } catch (error) {
      showError(`Failed to ${editingCustomer ? 'update' : 'create'} customer: ${error.message}`);
    }
  };

  const handleDelete = async () => {
    if (deletingCustomer) {
      try {
        // Delete from profiles table (customers are stored there)
        const { error } = await supabase
          .from('profiles')
          .delete()
          .eq('id', deletingCustomer.id);
          
        if (error) throw error;
        
        showSuccess(`Customer deleted successfully.\n\n${deletingCustomer.name} has been removed from the system.`);
        await loadCustomers();
        closeDeleteModal();
      } catch (error) {
        showError('Failed to delete customer. Please try again.');
      }
    }
  };

  // Get promoter name for display
  const getPromoterName = (customer) => {
    const promoterId = customer?.parent_promoter_id;
    if (!promoterId) return 'Unassigned';
    
    const promoter = (promoters || []).find(p => p?.id === promoterId);
    
    return promoter?.name || 'Unknown Promoter';
  };

  // Get promoter system ID for display
  const getPromoterSystemId = (customer) => {
    const promoterId = customer?.parent_promoter_id;
    if (!promoterId) return '';
    
    const promoter = (promoters || []).find(p => p?.id === promoterId);
    
    return promoter?.promoter_id || '';
  };

  return (
    <>
      <SharedStyles />
      <AdminNavbar />
      <UnifiedBackground>
        <div className="min-h-screen pt-40 px-8 pb-8">
          <div className="max-w-7xl mx-auto">
            {/* Header */}
            <div className="flex justify-between items-center mb-8" data-animate>
              <div>
                <h1 className="text-4xl font-bold text-white mb-2">Customer Management</h1>
                <p className="text-gray-300">Manage customer accounts and assignments</p>
              </div>
              <UnifiedButton
                onClick={openCreateModal}
                className="flex items-center space-x-2"
              >
                <Plus className="w-5 h-5" />
                <span>Create Customer</span>
              </UnifiedButton>
            </div>

            {/* Search and Filters */}
            <UnifiedCard className="p-6 mb-8" data-animate>
              <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
                <div className="flex-1 relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                  <input
                    type="text"
                    placeholder="Search by name, email, phone, or customer ID..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>
                <div className="flex gap-4">
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-green-500"
                  >
                    <option value="">All Status</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
              </div>
            </UnifiedCard>

            {/* Customers Table */}
            <UnifiedCard className="overflow-hidden" data-animate>
              
              {loading ? (
                <SkeletonTable rows={8} columns={6} />
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-700">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Customer Details</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Contact Details</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Saving Plan</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Assigned Promoter</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="bg-gray-800 divide-y divide-gray-700">
                      {filteredCustomers.length === 0 ? (
                        <tr>
                          <td colSpan="6" className="px-6 py-12 text-center text-gray-400">
                            No customers found
                          </td>
                        </tr>
                      ) : (
                        filteredCustomers.map((customer) => {
                          const customerId = customer?.id;
                          const customerName = customer?.name || 'Unknown';
                          const customerEmail = customer?.email || 'N/A';
                          const customerPhone = customer?.phone || 'N/A';
                          const systemCustomerID = customer?.customer_id || 'N/A';
                          const status = customer?.status || 'active';
                          const promoterName = getPromoterName(customer);
                          const promoterSystemId = getPromoterSystemId(customer);
                          
                          return (
                            <tr key={customerId} className="hover:bg-gray-700">
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="flex items-center">
                                  <div className="w-8 h-8 bg-gradient-to-r from-green-400 to-blue-500 rounded-full flex items-center justify-center mr-3">
                                    <Users className="w-4 h-4 text-white" />
                                  </div>
                                  <div className="flex flex-col">
                                    <span className="text-white font-medium">{customerName}</span>
                                    <span className="text-xs text-gray-400">{systemCustomerID}</span>
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <div className="space-y-1">
                                  <div className="flex items-center">
                                    <Mail className="w-3 h-3 mr-2 text-gray-400" />
                                    {customerEmail === 'N/A' ? 'No email' : customerEmail}
                                  </div>
                                  <div className="flex items-center">
                                    <Phone className="w-3 h-3 mr-2 text-gray-400" />
                                    {customerPhone === 'N/A' ? 'No phone' : customerPhone}
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-500/20 text-blue-400">
                                  ₹1000 × 20 months
                                </span>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <div className="flex items-center">
                                  <Users className="w-4 h-4 mr-2 text-blue-400" />
                                  <div className="flex flex-col">
                                    <span className="text-white font-medium">{promoterName}</span>
                                    {promoterSystemId && (
                                      <span className="text-xs text-gray-400">{promoterSystemId}</span>
                                    )}
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <button
                                  onClick={() => toggleCustomerStatus(customer)}
                                  className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium transition-colors ${
                                    status === 'active' 
                                      ? 'bg-green-100 text-green-800 hover:bg-green-200' 
                                      : 'bg-red-100 text-red-800 hover:bg-red-200'
                                  }`}
                                  title={`Click to ${status === 'active' ? 'deactivate' : 'activate'} customer`}
                                >
                                  {status === 'active' ? '✅ Active' : '❌ Inactive'}
                                </button>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                <div className="flex space-x-2">
                                  <button
                                    onClick={() => openPaymentManager(customer)}
                                    className="text-green-400 hover:text-green-300 transition-colors"
                                    title="Manage Payments"
                                  >
                                    <CreditCard className="w-4 h-4" />
                                  </button>
                                  <button
                                    onClick={() => openEditModal(customer)}
                                    className="text-orange-400 hover:text-orange-300 transition-colors"
                                    title="Edit Customer"
                                  >
                                    <Edit className="w-4 h-4" />
                                  </button>
                                  <button
                                    onClick={() => openDeleteModal(customer)}
                                    className="text-red-400 hover:text-red-300 transition-colors"
                                    title="Delete Customer"
                                  >
                                    <Trash2 className="w-4 h-4" />
                                  </button>
                                </div>
                              </td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              )}
            </UnifiedCard>
          </div>
        </div>

        {/* Unified Customer Form */}
        <UnifiedCustomerForm
          isOpen={showModal}
          onClose={closeModal}
          onSubmit={handleCustomerSubmit}
          promoters={getAllAvailableParents()}
          isEditing={!!editingCustomer}
          initialData={editingCustomer}
          currentUserRole="admin"
        />


        {/* Delete Confirmation Modal */}
        {showDeleteModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-gray-800 rounded-lg p-6 w-full max-w-md mx-4">
              <h3 className="text-lg font-semibold text-white mb-4">Confirm Delete</h3>
              <p className="text-gray-300 mb-6">
                Are you sure you want to delete customer "{deletingCustomer?.name}"? This action cannot be undone.
              </p>
              <div className="flex justify-end space-x-3">
                <button
                  onClick={closeDeleteModal}
                  className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleDelete}
                  className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Payment Manager */}
        <PaymentManager
          isOpen={showPaymentManager}
          onClose={closePaymentManager}
          customerId={selectedCustomerForPayments?.id}
          customerName={selectedCustomerForPayments?.name}
          currentUser={user}
        />
      </UnifiedBackground>
    </>
  );
}

export default AdminCustomers;
