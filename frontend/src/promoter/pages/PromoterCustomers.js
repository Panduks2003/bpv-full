import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import PromoterNavbar from '../components/PromoterNavbar';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { supabase } from "../../common/services/supabaseClient"
import { Search, Plus, Users, CreditCard, Mail, Phone, X, ArrowLeft } from 'lucide-react';
import { SkeletonFullPage } from '../components/skeletons';
import UnifiedCustomerForm from '../../common/components/UnifiedCustomerForm';
import PaymentManager from '../../common/components/PaymentManager';
import { useNavigate } from 'react-router-dom';

function PromoterCustomers() {
  const { user } = useAuth();
  const navigate = useNavigate();
  useScrollAnimation();

  // State management - unified with AdminCustomers
  const [customers, setCustomers] = useState([]);
  const [filteredCustomers, setFilteredCustomers] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [loading, setLoading] = useState(true);
  const [showPaymentManager, setShowPaymentManager] = useState(false);
  const [selectedCustomerForPayments, setSelectedCustomerForPayments] = useState(null);
  // Promoter-specific states
  const [availablePins, setAvailablePins] = useState(0);
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Filter and search logic - unified with AdminCustomers
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
      filtered = filtered.filter(customer => 
        (customer?.status || 'active') === statusFilter
      );
    }

    setFilteredCustomers(filtered);
  }, [customers, searchTerm, statusFilter]);

  // Load customers from Supabase - role-based filtering for promoters
  const loadCustomers = useCallback(async () => {
    if (!user?.id) return;
    
    try {
      setLoading(true);

      // Get customers assigned to this promoter (role-based access)
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
        .eq('parent_promoter_id', user.id)
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
  }, [user?.id]);

  // Load promoter pins
  const loadPromoterPins = useCallback(async () => {
    if (!user?.id) return;
    
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('pins')
        .eq('id', user.id)
        .single();
        
      if (error) {
        return;
      }
      
      setAvailablePins(data?.pins || 0);
    } catch (error) {
      setAvailablePins(0);
    }
  }, [user?.id]);

  // Load customers and pins on component mount
  useEffect(() => {
    loadCustomers();
    loadPromoterPins();
  }, [loadCustomers, loadPromoterPins]);

  // Payment management handlers
  const openPaymentManager = (customer) => {
    setSelectedCustomerForPayments(customer);
    setShowPaymentManager(true);
  };

  const closePaymentManager = () => {
    setShowPaymentManager(false);
    setSelectedCustomerForPayments(null);
  };

  // Customer creation modal handlers
  const openCreateModal = () => {
    setShowCreateModal(true);
  };

  const closeCreateModal = () => {
    setShowCreateModal(false);
  };

  // Handle customer creation
  const handleCreateCustomer = async (formData) => {
    try {
      
      // Validate required fields
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
      
      // Check if promoter has sufficient pins
      if (availablePins < 1) {
        throw new Error(`You have insufficient pins (${availablePins} available). Please request more pins from admin to create customers.`);
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
        p_parent_promoter_id: user.id, // Current promoter as parent
        p_email: formData.email?.trim() || null
      };
      
      // Create customer using the PIN deduction function (includes commission distribution)
      const { data: customerResult, error: customerError } = await supabase.rpc('create_customer_with_pin_deduction', dbParams);
      
      if (customerError || !customerResult?.success) {
        const errorMessage = customerResult?.error || customerError?.message || 'Failed to create customer';
        
        // Handle specific error types with user-friendly messages
        if (errorMessage.includes('Insufficient pins')) {
          throw new Error('You do not have enough PINs to create a new customer. Please request more PINs from admin first.');
        } else {
          throw new Error(errorMessage);
        }
      }
      
      // Show success message
      alert(`Customer Created Successfully!\n\nCard No: ${formData.cardNo}\nName: ${formData.name}\nLogin: Use Card No + Password\nPIN Balance: ₹20,000\nCommission: Distributed to hierarchy`);
      
      // Reload data
      await loadCustomers();
      await loadPromoterPins();
      closeCreateModal();
      
    } catch (error) {
      alert(`Failed to create customer: ${error.message}`);
    }
  };


  // Get promoter name for display (simplified for promoter view)
  const getPromoterName = (customer) => {
    const promoterId = customer?.parent_promoter_id;
    if (!promoterId) return 'Unassigned';
    
    // For promoter view, customers should be assigned to current promoter
    if (promoterId === user?.id) {
      return user?.name || 'You';
    }
    
    return 'Other Promoter';
  };

  // Get promoter system ID for display
  const getPromoterSystemId = (customer) => {
    const promoterId = customer?.parent_promoter_id;
    if (!promoterId || promoterId !== user?.id) return '';
    
    return user?.promoter_id || 'SELF';
  };

  return (
    <>
      <SharedStyles />
      <PromoterNavbar />
      <UnifiedBackground>
        <div className="min-h-screen pt-40 px-8 pb-8">
          <div className="max-w-7xl mx-auto">
            {/* Header with Pin Display */}
            <div className="flex justify-between items-center mb-8" data-animate>
              <div className="flex items-center space-x-4">
                <button
                  onClick={() => navigate('/promoter/home')}
                  className="p-2 rounded-lg bg-slate-700 hover:bg-slate-600 transition-colors"
                >
                  <ArrowLeft className="w-5 h-5 text-white" />
                </button>
                <div>
                  <h1 className="text-4xl font-bold text-white mb-2">Customer Management</h1>
                  <p className="text-gray-300">Manage your customer accounts and assignments</p>
                </div>
              </div>
              <div className="flex items-center space-x-4">
                {/* Create Customer Button */}
                <UnifiedButton 
                  onClick={openCreateModal}
                  disabled={availablePins < 1}
                  className="flex items-center space-x-2"
                >
                  <Plus className="w-5 h-5" />
                  <span>Create Customer</span>
                </UnifiedButton>
                
                {/* Pin Display */}
                <div className="bg-white rounded-lg p-4 min-w-[200px]">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-slate-600">Available Pins</p>
                      <p className={`text-3xl font-bold ${availablePins > 0 ? 'text-slate-900' : 'text-red-500'}`}>
                        {availablePins}
                      </p>
                      <p className="text-xs text-slate-500 mt-1">
                        {availablePins === 0 ? 'No pins available - contact admin' : 'Required: 1 pin per customer'}
                      </p>
                    </div>
                    <div className={`w-12 h-12 rounded-lg flex items-center justify-center ${
                      availablePins > 0 ? 'bg-orange-500' : 'bg-red-500'
                    }`}>
                      <svg className="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd"/>
                      </svg>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Search and Filters */}
            <UnifiedCard className="p-6 mb-8" data-animate>
              <div className="flex flex-col md:flex-row gap-4">
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
                <div className="p-8">
                  <SkeletonFullPage type="customers" />
                </div>
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
                                <span
                                  className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                    status === 'active' 
                                      ? 'bg-green-100 text-green-800' 
                                      : 'bg-red-100 text-red-800'
                                  }`}
                                >
                                  {status === 'active' ? '✅ Active' : '❌ Inactive'}
                                </span>
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

        {/* Payment Manager - View Only for Promoters */}
        <PaymentManager
          isOpen={showPaymentManager}
          onClose={closePaymentManager}
          customerId={selectedCustomerForPayments?.id}
          customerName={selectedCustomerForPayments?.name}
          currentUser={user}
          readOnly={true}
        />

        {/* Create Customer Modal */}
        {showCreateModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-slate-800 rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
              <div className="p-6 border-b border-slate-700">
                <div className="flex items-center justify-between">
                  <h3 className="text-xl font-bold text-white">Create New Customer</h3>
                  <button
                    onClick={closeCreateModal}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <X className="w-6 h-6" />
                  </button>
                </div>
              </div>
              
              <div className="p-6">
                <UnifiedCustomerForm
                  isOpen={showCreateModal}
                  onClose={closeCreateModal}
                  onSubmit={handleCreateCustomer}
                  promoters={[{ id: user.id, name: user.name || 'You', role: 'promoter' }]} // Current promoter as only option
                  isEditing={false}
                  initialData={{ parentPromoter: user.id }}
                  currentUserRole="promoter"
                />
              </div>
            </div>
          </div>
        )}

      </UnifiedBackground>
    </>
  );
}

export default PromoterCustomers;
