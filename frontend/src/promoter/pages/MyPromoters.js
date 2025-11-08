import React, { useState, useEffect } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import { useNavigate } from 'react-router-dom';
import { supabase } from "../../common/services/supabaseClient"
import PromoterNavbar from '../components/PromoterNavbar';
import UnifiedPromoterForm from '../../components/UnifiedPromoterForm';
import { 
  UnifiedBackground, 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation,
  SharedStyles
} from "../../common/components/SharedTheme";
import { SkeletonFullPage } from '../components/skeletons';
import { 
  Users, 
  Search, 
  Plus,
  Phone,
  Mail,
  Loader,
  Calendar,
  X,
  ArrowLeft,
  Award
} from 'lucide-react';

function MyPromoters() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [promoters, setPromoters] = useState([]);
  const [filteredPromoters, setFilteredPromoters] = useState([]);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedPromoter, setSelectedPromoter] = useState(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [stats, setStats] = useState({
    total: 0,
    level1: 0,
    level2Plus: 0,
    maxDepth: 0
  });
  
  useScrollAnimation();

  useEffect(() => {
    loadMyPromoters();
  }, [user]);

  const loadMyPromoters = async () => {
    if (!user?.promoter_id) return;
    
    try {
      setLoading(true);
      setError('');
      
      
      // Get COMPLETE downline hierarchy using the new get_promoter_downline_tree function
      const { data: downlineResult, error: downlineError } = await supabase
        .rpc('get_promoter_downline_tree', { p_promoter_code: user.promoter_id });
        
      if (downlineError) {
        
        // Fallback to direct children query
        const { data: promotersData, error: promotersError } = await supabase
          .from('profiles')
          .select(`
            id,
            name,
            email,
            phone,
            promoter_id,
            role_level,
            status,
            parent_promoter_id,
            pins,
            created_at,
            updated_at,
            parent_promoter:parent_promoter_id(
              id,
              name,
              promoter_id,
              role
            )
          `)
          .eq('role', 'promoter')
          .eq('parent_promoter_id', user.id)
          .order('created_at', { ascending: false });
          
        if (promotersError) {
          setError(`Failed to load promoters: ${promotersError.message || 'Unknown error'}`);
          return;
        }
        
        return processPromotersData(promotersData || []);
      }
      
      // Process the downline tree result
      if (downlineResult?.success && downlineResult?.downline_tree) {
        
        const downlinePromoters = downlineResult.downline_tree;
        
        // Get parent promoter info for each promoter in the downline
        const parentIds = downlinePromoters.map(p => {
          // Find parent ID from profiles table using promoter code
          return null; // We'll get this from the path information
        }).filter(Boolean);
        
        // Transform downline tree data to match expected format
        const promotersData = downlinePromoters.map(promoter => {
          // Determine parent from the path
          let parentPromoter = null;
          if (promoter.path && promoter.path.length > 1) {
            // Parent is the second-to-last in the path
            const parentCode = promoter.path[promoter.path.length - 2];
            if (parentCode !== user.promoter_id) {
              // Find parent in the downline list
              const parent = downlinePromoters.find(p => p.code === parentCode);
              if (parent) {
                parentPromoter = {
                  id: parent.id || parentCode,
                  name: parent.name,
                  promoter_id: parent.code,
                  role: 'promoter'
                };
              }
            } else {
              // Direct child - parent is current user
              parentPromoter = {
                id: user.id,
                name: user.name,
                promoter_id: user.promoter_id,
                role: 'promoter'
              };
            }
          } else {
            // Direct child - parent is current user
            parentPromoter = {
              id: user.id,
              name: user.name,
              promoter_id: user.promoter_id,
              role: 'promoter'
            };
          }
          
          return {
            id: promoter.id || promoter.code,
            name: promoter.name,
            email: promoter.email,
            phone: promoter.phone,
            promoter_id: promoter.code,
            role_level: promoter.role_level,
            status: promoter.status,
            parent_promoter_id: parentPromoter?.id,
            pins: 0, // Default value
            created_at: promoter.created_at,
            updated_at: promoter.created_at,
            parent_promoter: parentPromoter,
            hierarchy_level: promoter.level, // Add hierarchy level from tree
            hierarchy_path: promoter.path // Add full path
          };
        });
        
        return processPromotersData(promotersData);
      }
      
      // No downline found
      setPromoters([]);
      setFilteredPromoters([]);
      setLoading(false);
    } catch (err) {
      setError('Failed to load promoters: ' + err.message);
      setLoading(false);
    } finally {
      setLoading(false);
    }
  };
  
  // Process promoters data to add display fields
  const processPromotersData = (promotersData) => {
    if (!promotersData) {
      setPromoters([]);
      setFilteredPromoters([]);
      setStats({
        total: 0,
        level1: 0,
        level2Plus: 0,
        maxDepth: 0
      });
      setLoading(false);
      return;
    }
    
    // Transform data to include additional fields for display
    const transformedPromoters = (promotersData || []).map((promoter, index) => ({
      id: promoter?.id || index + 1,
      promoter_id: promoter?.promoter_id || `BPVP${String(index + 1).padStart(2, '0')}`,
      name: promoter?.name || 'Unknown Promoter',
      email: promoter?.email || 'No email',
      phone: promoter?.phone || 'No phone',
      joinDate: promoter?.created_at ? new Date(promoter.created_at).toISOString().split('T')[0] : '2024-01-01',
      affiliate_level: promoter?.role_level === 'Affiliate' ? 1 : 2,
      can_create_promoters: true, // Default for new promoters
      can_create_customers: true, // Default for new promoters
      commission_rate: 0.05, // Default commission rate
      status: promoter?.status || 'Active',
      pins: promoter?.pins || 0,
      parent_promoter: promoter?.parent_promoter || null,
      level: promoter?.level || 1, // Add level from hierarchy
      hierarchy_level: promoter?.hierarchy_level || 1, // Preserve hierarchy level from tree
      hierarchy_path: promoter?.hierarchy_path || [], // Preserve hierarchy path
      originalData: promoter
    }));

    // Calculate hierarchy statistics
    const hierarchyStats = {
      total: transformedPromoters.length,
      level1: transformedPromoters.filter(p => p.hierarchy_level === 1).length,
      level2Plus: transformedPromoters.filter(p => p.hierarchy_level >= 2).length,
      maxDepth: transformedPromoters.length > 0 ? Math.max(...transformedPromoters.map(p => p.hierarchy_level || 1)) : 0
    };

    setPromoters(transformedPromoters);
    setFilteredPromoters(transformedPromoters);
    setStats(hierarchyStats);
    setLoading(false);
  };

  // Filter and search logic
  useEffect(() => {
    let filtered = promoters || [];

    // Apply search filter
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

    // Apply status filter
    if (statusFilter && statusFilter !== 'all') {
      filtered = filtered.filter(promoter => {
        const promoterStatus = (promoter?.status || 'active').toLowerCase();
        return promoterStatus === statusFilter.toLowerCase();
      });
    }

    setFilteredPromoters(filtered);
  }, [promoters, searchTerm, statusFilter]);

  const openDetailsModal = (promoter) => {
    setSelectedPromoter(promoter);
    setShowDetailsModal(true);
  };

  const closeDetailsModal = () => {
    setShowDetailsModal(false);
    setSelectedPromoter(null);
  };

  const openCreateModal = () => {
    setShowCreateModal(true);
  };

  const closeCreateModal = () => {
    setShowCreateModal(false);
  };


  const handleCreatePromoter = async (formData) => {
    try {
      
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
      let authEmail = `promo${timestamp}${randomNum}@brightplanet.com`;
      
      // Step 2: Create auth user via backend service to avoid auth state changes
      
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
        
        // Fallback to direct signUp
        const signUpResult = await supabase.auth.signUp({
          email: authEmail,
          password: formData.password,
          options: {
            emailRedirectTo: undefined,
            data: {
              role: 'promoter',
              name: formData.name,
              phone: formData.phone
            }
          }
        });
        
        authData = signUpResult.data;
        authError = signUpResult.error;
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
      } else {
      }
      
      // Step 3: Create promoter profile in database
      const { data: result, error } = await supabase.rpc('create_promoter_with_auth_id', {
        p_name: formData.name.trim(),
        p_user_id: authData.user.id,
        p_auth_email: authEmail,
        p_password: formData.password.trim(),
        p_phone: formData.phone.trim(),
        p_email: formData.email && formData.email.trim() ? formData.email.trim() : null,
        p_address: formData.address && formData.address.trim() ? formData.address.trim() : null,
        p_parent_promoter_id: user.id, // Current promoter as parent
        p_role_level: 'Affiliate',
        p_status: 'Active'
      });
      
      if (error) {
        throw error;
      }
      
      if (!result || !result.success) {
        throw new Error(result?.error || 'Failed to create promoter profile');
      }
      
      
      // Reload promoters and close modal
      await loadMyPromoters();
      closeCreateModal();
      
      // Show clean success message
      alert(`Promoter Created Successfully!\n\nPromoter ID: ${result.promoter_id}\nName: ${result.name}\nLogin: Use Promoter ID + Password`);
      
    } catch (error) {
      alert(`Failed to create promoter: ${error.message}`);
    }
  };



  return (
    <>
      <SharedStyles />
      <PromoterNavbar />
      <UnifiedBackground>
        <div className="min-h-screen pt-40 px-8 pb-8">
          <div className="max-w-7xl mx-auto">
            {/* Header */}
            <div className="flex justify-between items-center mb-8" data-animate>
              <div className="flex items-center space-x-4">
                <button
                  onClick={() => navigate('/promoter/home')}
                  className="p-2 rounded-lg bg-slate-700 hover:bg-slate-600 transition-colors"
                >
                  <ArrowLeft className="w-5 h-5 text-white" />
                </button>
                <div>
                  <h1 className="text-4xl font-bold text-white mb-2">My Promoters</h1>
                  <p className="text-gray-300">Manage and track your promoter network</p>
                  {error && (
                    <p className="text-red-400 text-sm mt-2">⚠️ {error}</p>
                  )}
                </div>
              </div>
              <UnifiedButton 
                onClick={() => setShowCreateModal(true)}
                className="flex items-center space-x-2"
              >
                <Plus className="w-5 h-5" />
                <span>Create Promoter</span>
              </UnifiedButton>
            </div>

            {/* Stats Cards */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8" data-animate>
              <div className="bg-white/95 backdrop-blur-sm border border-slate-200 rounded-xl p-6 shadow-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-slate-600 mb-1 font-medium">Total Downline</p>
                    <p className="text-3xl font-bold text-slate-900">{stats.total}</p>
                  </div>
                  <div className="w-12 h-12 bg-blue-500 rounded-lg flex items-center justify-center">
                    <Users className="w-6 h-6 text-white" />
                  </div>
                </div>
              </div>

              <div className="bg-white/95 backdrop-blur-sm border border-slate-200 rounded-xl p-6 shadow-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-slate-600 mb-1 font-medium">Level 1 (Direct)</p>
                    <p className="text-3xl font-bold text-green-600">{stats.level1 || 0}</p>
                  </div>
                  <div className="w-12 h-12 bg-green-500 rounded-lg flex items-center justify-center">
                    <Award className="w-6 h-6 text-white" />
                  </div>
                </div>
              </div>

              <div className="bg-white/95 backdrop-blur-sm border border-slate-200 rounded-xl p-6 shadow-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-slate-600 mb-1 font-medium">Level 2+</p>
                    <p className="text-3xl font-bold text-purple-600">{stats.level2Plus || 0}</p>
                  </div>
                  <div className="w-12 h-12 bg-purple-500 rounded-lg flex items-center justify-center">
                    <Award className="w-6 h-6 text-white" />
                  </div>
                </div>
              </div>

              <div className="bg-white/95 backdrop-blur-sm border border-slate-200 rounded-xl p-6 shadow-lg">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-slate-600 mb-1 font-medium">Max Depth</p>
                    <p className="text-3xl font-bold text-orange-600">{stats.maxDepth || 0}</p>
                  </div>
                  <div className="w-12 h-12 bg-orange-500 rounded-lg flex items-center justify-center">
                    <Award className="w-6 h-6 text-white" />
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
                    placeholder="Search by name, email, promoter ID, or phone..."
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
                    <option value="all">All Status</option>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
              </div>
            </UnifiedCard>

            {/* Complete Downline Hierarchy Table */}
            <UnifiedCard className="overflow-hidden" data-animate>
              <div className="px-6 py-4 bg-gray-700 border-b border-gray-600">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-lg font-semibold text-white flex items-center">
                      <Users className="w-5 h-5 mr-2 text-blue-400" />
                      Complete Downline Hierarchy
                    </h3>
                  </div>
                  <div className="text-sm text-gray-400">
                    {filteredPromoters.length} of {promoters.length} promoters
                  </div>
                </div>
              </div>
              {loading ? (
                <div className="p-8">
                  <SkeletonFullPage type="promoters" />
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-gray-700">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Promoter Details</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Contact Details</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Parent Promoter</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Hierarchy Level</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Pins</th>
                      </tr>
                    </thead>
                    <tbody className="bg-gray-800 divide-y divide-gray-700">
                      {filteredPromoters.length === 0 ? (
                        <tr>
                          <td colSpan="6" className="px-6 py-12 text-center text-gray-400">
                            {promoters.length === 0 ? 'No promoters found. Start by creating your first promoter!' : 'No promoters match your search criteria.'}
                          </td>
                        </tr>
                      ) : (
                        filteredPromoters.map((promoter) => {
                          return (
                            <tr key={promoter.id} className="hover:bg-gray-700">
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="flex items-center">
                                  <div className="w-8 h-8 bg-gradient-to-r from-blue-400 to-purple-500 rounded-full flex items-center justify-center mr-3">
                                    <span className="text-white text-sm font-bold">{(promoter?.name || 'U').charAt(0)}</span>
                                  </div>
                                  <div className="flex flex-col">
                                    <span className="text-white font-medium">{promoter?.name || 'Unknown Promoter'}</span>
                                    <span className="text-xs text-gray-400">{promoter?.promoter_id || 'N/A'}</span>
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <div className="space-y-1">
                                  <div className="flex items-center">
                                    <Mail className="w-3 h-3 mr-2 text-gray-400" />
                                    {promoter?.email || 'No email'}
                                  </div>
                                  <div className="flex items-center">
                                    <Phone className="w-3 h-3 mr-2 text-gray-400" />
                                    {promoter?.phone || 'No phone'}
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <div className="flex items-center">
                                  {promoter?.parent_promoter?.role === 'admin' ? (                                    <>
                                      <span className="text-yellow-400 mr-2">👑</span>
                                      <span className="text-white font-medium">{promoter?.parent_promoter?.name || 'Admin'}</span>
                                    </>
                                  ) : (
                                    <>
                                      <Users className="w-4 h-4 mr-2 text-blue-400" />
                                      <div className="flex flex-col">
                                        <span className="text-white font-medium">{promoter?.parent_promoter?.name || user?.name || 'You'}</span>
                                        <span className="text-xs text-gray-400">{promoter?.parent_promoter?.promoter_id || 'Parent'}</span>
                                      </div>
                                    </>
                                  )}
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <div className="flex items-center">
                                  <div className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                    promoter?.hierarchy_level === 1 
                                      ? 'bg-green-100 text-green-800' 
                                      : promoter?.hierarchy_level === 2 
                                      ? 'bg-blue-100 text-blue-800'
                                      : promoter?.hierarchy_level === 3
                                      ? 'bg-purple-100 text-purple-800'
                                      : 'bg-orange-100 text-orange-800'
                                  }`}>
                                    <Award className="w-3 h-3 mr-1" />
                                    Level {promoter?.hierarchy_level || 1}
                                  </div>
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <span
                                  className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                    (promoter?.status || 'active').toLowerCase() === 'active' 
                                      ? 'bg-green-100 text-green-800' 
                                      : 'bg-red-100 text-red-800'
                                  }`}
                                >
                                  {(promoter?.status || 'active').toLowerCase() === 'active' ? '✅ Active' : '❌ Inactive'}
                                </span>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                <span className="text-sm font-medium text-white">📌 {promoter?.pins || 0}</span>
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

            {/* Promoter Details Modal */}
            {showDetailsModal && selectedPromoter && (
              <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
                <div className="bg-slate-800 rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                  <div className="p-6 border-b border-slate-700">
                    <div className="flex items-center justify-between">
                      <h3 className="text-xl font-bold text-white">Promoter Details</h3>
                      <button
                        onClick={closeDetailsModal}
                        className="text-gray-400 hover:text-white transition-colors"
                      >
                        <X className="w-6 h-6" />
                      </button>
                    </div>
                  </div>
                  
                  <div className="p-6">
                    <div className="flex items-center space-x-4 mb-6">
                      <div className="w-16 h-16 bg-gradient-to-r from-blue-400 to-purple-500 rounded-full flex items-center justify-center">
                        <span className="text-white text-xl font-bold">
                          {(selectedPromoter?.name || 'U').charAt(0)}
                        </span>
                      </div>
                      <div>
                        <h4 className="text-xl font-bold text-white">{selectedPromoter?.name || 'Unknown Promoter'}</h4>
                        <p className="text-gray-400">{selectedPromoter?.promoter_id}</p>
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium mt-2 bg-green-100 text-green-800">
                          Active
                        </span>
                      </div>
                    </div>

                    <div>
                      <h5 className="text-lg font-bold text-white mb-4">Promoter Information</h5>
                      <div className="space-y-4">
                        <div className="flex justify-between">
                          <span className="text-gray-400">Email</span>
                          <span className="text-white font-medium">{selectedPromoter?.email || 'No email'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Phone</span>
                          <span className="text-white font-medium">{selectedPromoter?.phone || 'No phone'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Join Date</span>
                          <span className="text-white font-medium">{selectedPromoter?.joinDate ? new Date(selectedPromoter.joinDate).toLocaleDateString() : 'N/A'}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Affiliate Level</span>
                          <span className="text-white font-medium">
                            {selectedPromoter?.level > 0 
                              ? `Downline Level ${selectedPromoter?.level}` 
                              : `Level ${selectedPromoter?.affiliate_level || 1}`}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Commission Rate</span>
                          <span className="text-white font-medium">{((selectedPromoter?.commission_rate || 0.05) * 100).toFixed(1)}%</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Can Create Promoters</span>
                          <span className={`font-medium ${selectedPromoter?.can_create_promoters ? 'text-green-400' : 'text-red-400'}`}>
                            {selectedPromoter?.can_create_promoters ? 'Yes' : 'No'}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-400">Can Create Customers</span>
                          <span className={`font-medium ${selectedPromoter?.can_create_customers ? 'text-green-400' : 'text-red-400'}`}>
                            {selectedPromoter?.can_create_customers ? 'Yes' : 'No'}
                          </span>
                        </div>
                      </div>

                      <div className="mt-6 space-y-2">
                        <UnifiedButton className="w-full flex items-center justify-center space-x-2">
                          <Mail className="w-4 h-4" />
                          <span>Contact Promoter</span>
                        </UnifiedButton>
                        <button className="w-full px-4 py-2 bg-slate-700 text-white rounded-lg hover:bg-slate-600 transition-colors">
                          View Performance
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Create Promoter Modal */}
            {showCreateModal && (
              <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
                <div className="bg-slate-800 rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                  <div className="p-6 border-b border-slate-700">
                    <div className="flex items-center justify-between">
                      <h3 className="text-xl font-bold text-white">Create New Promoter</h3>
                      <button
                        onClick={closeCreateModal}
                        className="text-gray-400 hover:text-white transition-colors"
                      >
                        <X className="w-6 h-6" />
                      </button>
                    </div>
                  </div>
                  
                  <div className="p-6">
                    <UnifiedPromoterForm
                      onSubmit={handleCreatePromoter}
                      onCancel={closeCreateModal}
                      hideParentPromoter={true}
                      submitButtonText="Create Promoter"
                    />
                  </div>
                </div>
              </div>
            )}

          </div>
        </div>
      </UnifiedBackground>
    </>
  );
}

export default MyPromoters;
