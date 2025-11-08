import React, { useState, useEffect, useCallback } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import AdminNavbar from '../components/AdminNavbar';
import UnifiedPromoterForm from '../../components/UnifiedPromoterForm';
import SuccessModal from '../../common/components/SuccessModal';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { supabase } from "../../common/services/supabaseClient"
import { Search, Plus, Edit, Trash2, Users, Mail, Phone, Shield, X, Loader } from 'lucide-react';
import { SkeletonTable } from '../components/skeletons';
import { useToast } from '../services/toastService';

function AdminPromoters() {
  const { user } = useAuth();
  const { showSuccess, showError, showWarning, handleApiError } = useToast();
  useScrollAnimation();

  // State management
  const [promoters, setPromoters] = useState([]);
  const [filteredPromoters, setFilteredPromoters] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [editingPromoter, setEditingPromoter] = useState(null);
  const [deletingPromoter, setDeletingPromoter] = useState(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [successData, setSuccessData] = useState(null);
  const [showPinModal, setShowPinModal] = useState(false);
  const [selectedPromoterForPins, setSelectedPromoterForPins] = useState(null);
  const [pinAllocation, setPinAllocation] = useState({ amount: '', notes: '' });
  const [adminUsers] = useState([]);

  // Load promoters on component mount
  useEffect(() => {
    loadPromoters();
  }, []);

  // Filter and search logic
  useEffect(() => {
    let filtered = promoters || [];

    // Search filter
    if (searchTerm) {
      filtered = filtered.filter(promoter => {
        const name = (promoter?.name || '').toLowerCase();
        const email = (promoter?.email || '').toLowerCase();
        const promoterId = (promoter?.promoter_id || '').toLowerCase();
        const phone = (promoter?.phone || '').toLowerCase();
        const searchLower = (searchTerm || '').toLowerCase();
        return name.includes(searchLower) || 
               email.includes(searchLower) || 
               promoterId.includes(searchLower) ||
               phone.includes(searchLower);
      });
    }

    // Status filter
    if (statusFilter) {
      filtered = filtered.filter(promoter => {
        const promoterStatus = (promoter?.status || 'active').toLowerCase();
        return promoterStatus === statusFilter.toLowerCase();
      });
    }

    setFilteredPromoters(filtered);
  }, [promoters, searchTerm, statusFilter]);

  // Load promoters from Supabase
  const loadPromoters = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('role', 'promoter')
        .order('created_at', { ascending: false });
      if (error) {
        throw error;
      }
      setPromoters(data || []);
    } catch (error) {
      setPromoters([]);
    } finally {
      setLoading(false);
    }
  };


  // Form validation is now handled by UnifiedPromoterForm

  // Modal handlers
  const openCreateModal = () => {
    setEditingPromoter(null);
    setShowModal(true);
  };

  const openEditModal = (promoter) => {
    setEditingPromoter(promoter);
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingPromoter(null);
  };

  const openDeleteModal = (promoter) => {
    setDeletingPromoter(promoter);
    setShowDeleteModal(true);
  };

  const closeDeleteModal = () => {
    setShowDeleteModal(false);
    setDeletingPromoter(null);
  };

  // Toggle promoter status
  const togglePromoterStatus = async (promoter) => {
    try {
      const currentStatus = promoter.status?.toLowerCase();
      const newStatus = currentStatus === 'active' ? 'Inactive' : 'Active';
      
      // Update status in profiles table (where the main status is stored)
      const { error } = await supabase
        .from('profiles')
        .update({ status: newStatus })
        .eq('id', promoter.id);
      
      if (error) {
        throw error;
      }
      
      
      // Reload promoters to reflect changes
      await loadPromoters();
      showSuccess(`Promoter status updated from ${currentStatus} to ${newStatus}`);
    } catch (error) {
      handleApiError(error, 'Failed to update promoter status');
    }
  };

  // Handle form submission from UnifiedPromoterForm
  const handleFormSubmit = async (formData) => {
    setSubmitting(true);
    
    // Store current admin session to prevent interference
    const currentSession = await supabase.auth.getSession();
    const currentUser = currentSession.data.session?.user;
    
    try {
      if (editingPromoter) {
        // Update existing promoter (excluding parent promoter to preserve hierarchy)
        const { data, error } = await supabase.rpc('update_promoter_profile', {
          p_promoter_id: editingPromoter.promoter_id,
          p_name: formData.name,
          p_email: formData.email,
          p_phone: formData.phone,
          p_address: formData.address,
          p_status: formData.status,
          p_parent_promoter_id: editingPromoter.parent_promoter_id // Keep original parent promoter
        });
        
        if (error) throw error;
        
        if (!data.success) {
          throw new Error(data.error || 'Failed to update promoter');
        }
        
        showSuccess('Promoter updated successfully');
      } else {
        // Create new promoter using admin.createUser to avoid auth context interference
        
        // Validate required fields
        if (!formData.name || formData.name.trim() === '') {
          throw new Error('Name is required for promoter creation.');
        }
        
        if (!formData.password || formData.password.trim() === '') {
          throw new Error('Password is required for promoter creation.');
        }
        
        if (!formData.phone || formData.phone.trim() === '') {
          throw new Error('Phone number is required for promoter creation.');
        }
        
        // Step 1: Generate unique auth email
        const timestamp = Date.now();
        const randomNum = Math.floor(Math.random() * 1000000);
        const authEmail = `promo${timestamp}${randomNum}@brightplanet.com`;
        
        
        // Step 2: Create auth user via backend service to avoid frontend auth state changes
        let authData, authError;
        
        try {
          // Try to create user via backend service first (if available)
          const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';
          const backendResponse = await fetch(`${API_URL}/create-promoter-auth`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              email: authEmail,
              password: formData.password,
              userData: {
                role: 'promoter',
                name: formData.name,
                phone: formData.phone
              }
            })
          });
          
          if (backendResponse.ok) {
            const result = await backendResponse.json();
            authData = { user: result.user };
          } else {
            throw new Error('Backend service not available');
          }
          
        } catch (backendError) {
          
          // Fallback to direct signUp with session management
          const signUpResult = await supabase.auth.signUp({
            email: authEmail,
            password: formData.password,
            options: {
              emailRedirectTo: undefined, // Don't send confirmation email
              data: {
                role: 'promoter',
                name: formData.name,
                phone: formData.phone
              }
            }
          });
          
          authData = signUpResult.data;
          authError = signUpResult.error;
          
          // Immediately restore admin session after signUp to prevent auth context confusion
          if (currentUser && currentSession.data.session) {
            await supabase.auth.setSession(currentSession.data.session);
          }
        }
        
        if (authError) {
          if (authError.message?.includes('already registered')) {
            throw new Error(`Email ${authEmail} is already registered. Please try again.`);
          }
          throw new Error('Failed to create auth user: ' + authError.message);
        }
        
        if (!authData.user) {
          throw new Error('Failed to create auth user: No user data returned');
        }
        
        
        // Step 2b: Manually confirm the email in database
        const { error: confirmError } = await supabase.rpc('confirm_promoter_email', {
          p_user_id: authData.user.id
        });
        
        if (confirmError) {
        }
        
        // Step 3: Create promoter profile in database
        const { data, error } = await supabase.rpc('create_promoter_with_auth_id', {
          p_name: formData.name.trim(),
          p_user_id: authData.user.id,
          p_auth_email: authEmail,
          p_password: formData.password.trim(),
          p_phone: formData.phone.trim(),
          p_email: formData.email && formData.email.trim() ? formData.email.trim() : null,
          p_address: formData.address && formData.address.trim() ? formData.address.trim() : null,
          p_parent_promoter_id: formData.parentPromoter || null,
          p_role_level: 'Affiliate',
          p_status: 'Active'
        });
        
        if (error) {
          
          // If profile creation fails, clean up the auth user
          try {
            // Try admin delete first, fallback to signOut if not available
            try {
              await supabase.auth.admin.deleteUser(authData.user.id);
            } catch (adminError) {
            }
          } catch (cleanupError) {
            // Cleanup failed silently
          }
          
          // Handle specific database errors
          if (error.message?.includes('UPDATE requires a WHERE clause')) {
            throw new Error('Database configuration error. Please run the database fix script first.');
          }
          
          throw new Error(error.message || 'Failed to create promoter profile');
        }
        
        if (!data || !data.success) {
          // Clean up auth user if profile creation fails
          try {
            // Try admin delete first, fallback to signOut if not available
            try {
              await supabase.auth.admin.deleteUser(authData.user.id);
            } catch (adminError) {
            }
          } catch (cleanupError) {
            // Cleanup failed silently
          }
          
          throw new Error(data?.error || 'Failed to create promoter profile');
        }
        
        
        // Show clean, centered success modal
        setSuccessData({
          title: 'Success!',
          message: 'Promoter created successfully and is ready to use.',
          details: `Promoter ID: ${data.promoter_id}\nName: ${data.name}\nLogin: Use Promoter ID + Password`
        });
        setShowSuccessModal(true);
        
        // Ensure admin session is restored (prevent auth context confusion)
        if (currentUser && currentSession.data.session) {
          // The admin session should remain active since we used admin.createUser
        }
      }

      // Reload promoters
      await loadPromoters();
      closeModal();
    } catch (error) {
      handleApiError(error, 'Failed to save promoter');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async () => {
    if (deletingPromoter) {
      try {
        const { error } = await supabase
          .from('profiles')
          .delete()
          .eq('id', deletingPromoter.id);
        if (error) throw error;
        await loadPromoters();
        closeDeleteModal();
      } catch (error) {
        handleApiError(error, 'Failed to delete promoter');
      }
    }
  };

  // Pin allocation functions
  const openPinModal = (promoter) => {
    setSelectedPromoterForPins(promoter);
    setPinAllocation({ amount: '', notes: '' });
    setShowPinModal(true);
  };

  const closePinModal = () => {
    setShowPinModal(false);
    setSelectedPromoterForPins(null);
    setPinAllocation({ amount: '', notes: '' });
  };

  const handlePinAllocation = async () => {
    if (!selectedPromoterForPins || !pinAllocation.amount) {
      showWarning('Please enter a valid pin amount');
      return;
    }

    const amount = parseInt(pinAllocation.amount);
    if (amount <= 0) {
      showWarning('Pin amount must be greater than 0');
      return;
    }

    try {
      setSubmitting(true);
      
      // Call the database function to add pins
      const { data: result, error } = await supabase.rpc('add_promoter_pins', {
        p_promoter_id: selectedPromoterForPins.id,
        p_pins_to_add: amount
      });

      if (error) {
        throw new Error(error.message);
      }

      // Log the pin allocation
      await supabase.from('pin_usage_log').insert({
        promoter_id: selectedPromoterForPins.id,
        pins_used: -amount, // Negative for allocation (positive for usage)
        action_type: 'admin_allocation',
        notes: pinAllocation.notes || `Admin allocated ${amount} pins`
      });

      showSuccess(`${amount} pins allocated to ${selectedPromoterForPins.name} successfully`);
      
      // Reload promoters to show updated pin counts
      await loadPromoters();
      closePinModal();
      
    } catch (error) {
      handleApiError(error, 'Failed to allocate pins');
    } finally {
      setSubmitting(false);
    }
  };

  // Get parent promoter info for display (ID + Name)
  const getParentPromoterInfo = (promoter) => {
    const parentId = promoter?.parent_promoter_id;
    if (!parentId) return null;
    
    // Check if parent is an admin user first
    const parentAdmin = (adminUsers || []).find(admin => admin.id === parentId);
    if (parentAdmin) {
      return {
        name: parentAdmin.name || 'Admin',
        id: 'Admin',
        isAdmin: true
      };
    }
    
    // Check if parent is a promoter
    const parentPromoter = (promoters || []).find(p => 
      p?.id === parentId
    );
    
    if (parentPromoter) {
      return {
        name: parentPromoter.name || 'Unknown',
        id: parentPromoter.promoter_id || 'N/A',
        isAdmin: false
      };
    }
    
    return {
      name: 'Unknown Parent',
      id: 'N/A',
      isAdmin: false
    };
  };

  // Get available parent promoters (excluding admin users since they're passed separately)
  const getAvailableParents = () => {
    const allPromoters = promoters || [];
    
    // Return only promoters (admin users are handled separately in UnifiedPromoterForm)
    const allAvailableParents = [...allPromoters];
    
    if (!editingPromoter) return allAvailableParents;
    
    const getDescendants = (promoterId, allPromoters) => {
      const descendants = [];
      const children = allPromoters.filter(p => 
        p?.parent_promoter_id === promoterId
      );
      children.forEach(child => {
        const childId = child?.id;
        if (childId) {
          descendants.push(childId);
          descendants.push(...getDescendants(childId, allPromoters));
        }
      });
      return descendants;
    };

    const currentId = editingPromoter?.id;
    if (!currentId) return allAvailableParents;
    
    const excludeIds = [currentId, ...getDescendants(currentId, allPromoters)];
    return allAvailableParents.filter(p => {
      const parentId = p?.id;
      // Admin users are never excluded (they can always be parent promoters)
      return parentId && (p?.isAdmin || !excludeIds.includes(parentId));
    });
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
                <h1 className="text-4xl font-bold text-white mb-2">
                  Promoter Management
                </h1>
                <p className="text-gray-400">
                  Manage promoters, hierarchies, and performance
                </p>
              </div>
              <UnifiedButton onClick={openCreateModal} className="flex items-center space-x-2">
                <Plus className="w-5 h-5" />
                <span>Create Promoter</span>
              </UnifiedButton>
            </div>

            {/* Search and Filters */}
            <UnifiedCard className="mb-6" data-animate>
              <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
                <div className="flex-1">
                  <input
                    type="text"
                    placeholder="Search by name, email, ID, or phone..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-orange-500"
                  />
                </div>
                <div className="flex gap-4">
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                    className="px-4 py-2 bg-gray-700 border border-gray-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-orange-500"
                  >
                    <option value="">All Status</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
              </div>
            </UnifiedCard>

            {/* Promoters Table */}
            <UnifiedCard className="overflow-hidden" data-animate>
              {loading ? (
                <SkeletonTable rows={8} columns={6} />
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-700">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Promoter Details</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Contact Details</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Parent Promoter</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Pins</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="bg-gray-800 divide-y divide-gray-700">
                      {filteredPromoters.length === 0 ? (
                        <tr>
                          <td colSpan="6" className="px-6 py-12 text-center text-gray-400">
                            No promoters found
                          </td>
                        </tr>
                      ) : (
                        filteredPromoters.map((promoter) => {
                          const promoterId = promoter?.id;
                          const promoterName = promoter?.name || 'Unknown';
                          const promoterEmail = promoter?.email || 'N/A';
                          const promoterPhone = promoter?.phone || 'N/A';
                          const systemPromoterID = promoter?.promoter_id || 'N/A';
                          const status = (promoter?.status || 'Active').toLowerCase();
                          
                          return (
                            <tr key={promoterId} className="hover:bg-gray-700">
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="flex items-center">
                                  <div className="w-8 h-8 bg-gradient-to-r from-orange-400 to-yellow-500 rounded-full flex items-center justify-center mr-3">
                                    <Users className="w-4 h-4 text-white" />
                                  </div>
                                  <div className="flex flex-col">
                                    <span className="text-white font-medium">{promoterName}</span>
                                    <span className="text-xs text-gray-400">{systemPromoterID}</span>
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <div className="space-y-1">
                                  <div className="flex items-center">
                                    <Mail className="w-3 h-3 mr-2 text-gray-400" />
                                    {promoterEmail === 'N/A' ? 'No email' : promoterEmail}
                                  </div>
                                  <div className="flex items-center">
                                    <Phone className="w-3 h-3 mr-2 text-gray-400" />
                                    {promoterPhone || 'No phone'}
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                {(() => {
                                  const parentInfo = getParentPromoterInfo(promoter);
                                  if (!parentInfo) return '-';
                                  
                                  return (
                                    <div className="flex items-center">
                                      {parentInfo.isAdmin ? (
                                        <>
                                          <span className="text-yellow-400 mr-2">👑</span>
                                          <span className="text-white font-medium">{parentInfo.name}</span>
                                        </>
                                      ) : (
                                        <>
                                          <Users className="w-4 h-4 mr-2 text-blue-400" />
                                          <div className="flex flex-col">
                                            <span className="text-white font-medium">{parentInfo.name}</span>
                                            <span className="text-xs text-gray-400">{parentInfo.id}</span>
                                          </div>
                                        </>
                                      )}
                                    </div>
                                  );
                                })()}
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <button
                                  onClick={() => togglePromoterStatus(promoter)}
                                  className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium transition-colors hover:opacity-80 cursor-pointer ${
                                    status === 'active' 
                                      ? 'bg-green-100 text-green-800 hover:bg-green-200' 
                                      : 'bg-red-100 text-red-800 hover:bg-red-200'
                                  }`}
                                  title="Click to toggle status"
                                >
                                  {status === 'active' ? '✅ Active' : '❌ Inactive'}
                                </button>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <span className="text-sm font-medium text-white">📌 {promoter?.pins || 0}</span>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                <div className="flex space-x-2">
                                  <button
                                    onClick={() => openEditModal(promoter)}
                                    className="text-orange-400 hover:text-orange-300 transition-colors"
                                  >
                                    <Edit className="w-4 h-4" />
                                  </button>
                                  <button
                                    onClick={() => openDeleteModal(promoter)}
                                    className="text-red-400 hover:text-red-300 transition-colors"
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

        {/* Create/Edit Modal */}
        {showModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <UnifiedPromoterForm
              onSubmit={handleFormSubmit}
              onCancel={closeModal}
              loading={submitting}
              editingPromoter={editingPromoter}
              availableParents={getAvailableParents()}
              adminUsers={adminUsers}
            />
          </div>
        )}

        {/* Delete Confirmation Modal */}
        {showDeleteModal && deletingPromoter && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-gray-800 rounded-lg p-6 w-full max-w-md mx-4">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-semibold text-white">Confirm Delete</h3>
                <button
                  onClick={closeDeleteModal}
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="mb-6">
                <p className="text-gray-300">
                  Are you sure you want to delete promoter <strong>{deletingPromoter.name}</strong>?
                </p>
                <p className="text-red-400 text-sm mt-2">
                  This action cannot be undone.
                </p>
              </div>

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

        {/* Pin Allocation Modal */}
        {showPinModal && selectedPromoterForPins && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
            <div className="bg-gray-800 rounded-xl p-6 w-full max-w-md border border-gray-700">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-xl font-semibold text-white">Allocate Pins</h3>
                <button
                  onClick={closePinModal}
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="space-y-4">
                <div>
                  <p className="text-gray-300 mb-2">
                    Promoter: <span className="font-semibold text-white">{selectedPromoterForPins.name}</span>
                  </p>
                  <p className="text-gray-300 mb-4">
                    Current Pins: <span className={`font-bold ${(selectedPromoterForPins?.pins || 0) > 0 ? 'text-green-400' : 'text-red-400'}`}>
                      {selectedPromoterForPins?.pins || 0}
                    </span>
                  </p>
                </div>

                <div>
                  <label className="block text-gray-300 text-sm mb-2">
                    Number of Pins to Allocate <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="1000"
                    value={pinAllocation.amount}
                    onChange={(e) => setPinAllocation(prev => ({ ...prev, amount: e.target.value }))}
                    placeholder="Enter number of pins"
                    className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                  />
                </div>

                <div>
                  <label className="block text-gray-300 text-sm mb-2">
                    Notes (Optional)
                  </label>
                  <textarea
                    value={pinAllocation.notes}
                    onChange={(e) => setPinAllocation(prev => ({ ...prev, notes: e.target.value }))}
                    placeholder="Add notes about this allocation..."
                    rows="3"
                    className="w-full px-4 py-3 bg-gray-700 border border-gray-600 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-orange-500 focus:ring-2 focus:ring-orange-500/20"
                  />
                </div>

                <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4">
                  <div className="flex items-start space-x-3">
                    <Shield className="w-5 h-5 text-blue-400 mt-0.5" />
                    <div>
                      <p className="text-blue-300 text-sm font-medium">Pin Allocation Info</p>
                      <p className="text-gray-300 text-sm mt-1">
                        Each customer creation requires 1 pin. Allocate pins to enable promoters to create customers.
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <div className="flex justify-end space-x-3 mt-6">
                <button
                  onClick={closePinModal}
                  className="px-4 py-2 text-gray-300 hover:text-white transition-colors"
                  disabled={submitting}
                >
                  Cancel
                </button>
                <button
                  onClick={handlePinAllocation}
                  disabled={submitting || !pinAllocation.amount}
                  className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
                >
                  {submitting ? (
                    <>
                      <Loader className="w-4 h-4 animate-spin" />
                      <span>Allocating...</span>
                    </>
                  ) : (
                    <>
                      <Shield className="w-4 h-4" />
                      <span>Allocate Pins</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Success Modal */}
        <SuccessModal
          isOpen={showSuccessModal}
          onClose={() => {
            setShowSuccessModal(false);
            setSuccessData(null);
          }}
          title={successData?.title}
          message={successData?.message}
          details={successData?.details}
        />
      </UnifiedBackground>
    </>
  );
}

export default AdminPromoters;
