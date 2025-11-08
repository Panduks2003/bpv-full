import React, { useState, useEffect } from 'react';
import { useAuth } from "../../common/context/AuthContext";
import CustomerNavbar from '../components/CustomerNavbar';
import Footer from '../../common/components/Footer';
import { UnifiedBackground, UnifiedCard, UnifiedButton } from "../../common/components/SharedTheme";
import { supabase } from "../../common/services/supabaseClient"
import { User, Mail, Phone, Calendar, Shield, TrendingUp, Edit3, Save, X, Check } from 'lucide-react';

function CustomerProfile() {
  const { user } = useAuth();
  const [customerData, setCustomerData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [profileData, setProfileData] = useState({
    name: '',
    email: '',
    phone: '',
    saving: ''
  });
  const [savingData, setSavingData] = useState({
    totalSaved: 0,
    totalReturns: 0,
    activeSavings: 0
  });

  // Edit functionality state
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState({
    name: '',
    phone: '',
    saving: ''
  });
  const [saving, setSaving] = useState(false);
  const [saveMessage, setSaveMessage] = useState('');

  useEffect(() => {
    loadCustomerData();
  }, [user]);

  const loadCustomerData = async () => {
    if (!user) return;
    
    try {
      setLoading(true);
      console.log('🔍 Loading customer data for user:', user.id);
      
      // Load from profiles table (main source since customers table doesn't exist)
      const { data: profileRecord, error: profileError } = await supabase
        .from('profiles')
        .select('*, created_at')
        .eq('id', user.id)
        .single();
        
      if (profileRecord && !profileError) {
        console.log('✅ Found profile record:', profileRecord);
        setCustomerData(profileRecord);
        setProfileData({
          name: profileRecord.name || '',
          email: profileRecord.email || '',
          phone: profileRecord.phone || '',
          saving: profileRecord.saving || ''
        });
      } else {
        console.error('❌ No profile data found, using auth data');
        // Use user data as fallback
        setProfileData({
          name: user.user_metadata?.name || user.name || '',
          email: user.email || '',
          phone: user.user_metadata?.phone || ''
        });
      }
    } catch (error) {
      console.error('❌ Error loading customer data:', error);
      // Use user data as fallback on error
      setProfileData({
        name: user.user_metadata?.name || user.name || '',
        email: user.email || '',
        phone: user.user_metadata?.phone || ''
      });
    } finally {
      setLoading(false);
    }
  };

  const memberSince = customerData?.created_at ? 
    new Date(customerData.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long' }) : 
    "Recently joined";

  // Edit functionality methods
  const handleEditClick = () => {
    setIsEditing(true);
    setEditData({
      name: profileData.name || '',
      phone: profileData.phone || '',
      saving: profileData.saving || ''
    });
    setSaveMessage('');
  };

  const handleCancelEdit = () => {
    setIsEditing(false);
    setEditData({
      name: '',
      phone: '',
      saving: ''
    });
    setSaveMessage('');
  };

  const handleInputChange = (field, value) => {
    setEditData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleSaveProfile = async () => {
    if (!user) return;
    
    try {
      setSaving(true);
      setSaveMessage('');
      
      console.log('💾 Saving profile updates for user:', user.id);
      
      // Update the profiles table
      const { data, error } = await supabase
        .from('profiles')
        .update({
          name: editData.name,
          phone: editData.phone,
          saving: editData.saving,
          updated_at: new Date().toISOString()
        })
        .eq('id', user.id)
        .select()
        .single();

      if (error) {
        console.error('❌ Error updating profile:', error);
        setSaveMessage('Error updating profile. Please try again.');
        return;
      }

      console.log('✅ Profile updated successfully:', data);
      
      // Update local state
      setProfileData(prev => ({
        ...prev,
        name: editData.name,
        phone: editData.phone,
        saving: editData.saving
      }));
      
      setCustomerData(prev => ({
        ...prev,
        name: editData.name,
        phone: editData.phone,
        saving: editData.saving
      }));
      
      setIsEditing(false);
      setSaveMessage('Profile updated successfully!');
      
      // Clear success message after 3 seconds
      setTimeout(() => {
        setSaveMessage('');
      }, 3000);
      
    } catch (error) {
      console.error('❌ Error saving profile:', error);
      setSaveMessage('Error updating profile. Please try again.');
    } finally {
      setSaving(false);
    }
  };



  if (loading) {
    return (
      <UnifiedBackground>
        <CustomerNavbar />
        <div className="min-h-screen flex items-center justify-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-orange-400"></div>
        </div>
      </UnifiedBackground>
    );
  }

  return (
    <UnifiedBackground>
      <CustomerNavbar />
      <div className="min-h-screen p-6">
        <div className="w-full mx-auto">
          
          {/* Header */}
          <div className="text-center mb-8">
            <div className="w-24 h-24 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4">
              <User className="w-12 h-12 text-white" />
            </div>
            <h1 className="text-4xl font-bold text-white mb-2">My Profile</h1>
            <p className="text-gray-400">Manage your account information</p>
          </div>

          {/* Profile Card */}
          <UnifiedCard className="p-10 mb-8 bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-slate-700/50 shadow-2xl">
            <div className="mb-8 text-center">
              <div className="flex items-center justify-between">
                <h2 className="text-3xl font-bold text-white mb-2">Personal Information</h2>
                {!isEditing ? (
                  <UnifiedButton
                    onClick={handleEditClick}
                    className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
                  >
                    <Edit3 className="w-4 h-4" />
                    Edit Profile
                  </UnifiedButton>
                ) : (
                  <div className="flex items-center gap-2">
                    <UnifiedButton
                      onClick={handleSaveProfile}
                      disabled={saving}
                      className="flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors disabled:opacity-50"
                    >
                      {saving ? (
                        <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                      ) : (
                        <Save className="w-4 h-4" />
                      )}
                      {saving ? 'Saving...' : 'Save'}
                    </UnifiedButton>
                    <UnifiedButton
                      onClick={handleCancelEdit}
                      className="flex items-center gap-2 px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg transition-colors"
                    >
                      <X className="w-4 h-4" />
                      Cancel
                    </UnifiedButton>
                  </div>
                )}
              </div>
              <div className="w-24 h-1 bg-gradient-to-r from-blue-500 to-purple-600 mx-auto rounded-full"></div>
            </div>

            {/* Save Message */}
            {saveMessage && (
              <div className={`mb-6 p-4 rounded-lg text-center ${
                saveMessage.includes('successfully') 
                  ? 'bg-green-500/20 border border-green-500/30 text-green-300' 
                  : 'bg-red-500/20 border border-red-500/30 text-red-300'
              }`}>
                {saveMessage}
              </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              
              {/* Name */}
              <div className="bg-gradient-to-br from-slate-700/30 to-slate-800/30 p-6 rounded-xl border border-slate-600/30 hover:border-slate-500/50 transition-all duration-300">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-blue-500/20 rounded-lg flex items-center justify-center">
                    <User className="w-5 h-5 text-blue-400" />
                  </div>
                  <h3 className="text-lg font-semibold text-white">Full Name</h3>
                </div>
                {isEditing ? (
                  <input
                    type="text"
                    value={editData.name}
                    onChange={(e) => handleInputChange('name', e.target.value)}
                    className="w-full px-4 py-3 bg-slate-800/50 border border-slate-600 rounded-lg text-white placeholder-gray-400 focus:border-blue-500 focus:outline-none"
                    placeholder="Enter your full name"
                  />
                ) : (
                  <p className="text-2xl font-bold text-gray-100">{profileData.name || 'Not specified'}</p>
                )}
              </div>

              {/* Email */}
              <div className="bg-gradient-to-br from-slate-700/30 to-slate-800/30 p-6 rounded-xl border border-slate-600/30 hover:border-slate-500/50 transition-all duration-300">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-green-500/20 rounded-lg flex items-center justify-center">
                    <Mail className="w-5 h-5 text-green-400" />
                  </div>
                  <h3 className="text-lg font-semibold text-white">Email Address</h3>
                </div>
                <p className="text-xl font-medium text-gray-100 break-all">{profileData.email || 'Not specified'}</p>
              </div>

              {/* Phone */}
              <div className="bg-gradient-to-br from-slate-700/30 to-slate-800/30 p-6 rounded-xl border border-slate-600/30 hover:border-slate-500/50 transition-all duration-300">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-purple-500/20 rounded-lg flex items-center justify-center">
                    <Phone className="w-5 h-5 text-purple-400" />
                  </div>
                  <h3 className="text-lg font-semibold text-white">Phone Number</h3>
                </div>
                {isEditing ? (
                  <input
                    type="tel"
                    value={editData.phone}
                    onChange={(e) => handleInputChange('phone', e.target.value)}
                    className="w-full px-4 py-3 bg-slate-800/50 border border-slate-600 rounded-lg text-white placeholder-gray-400 focus:border-purple-500 focus:outline-none"
                    placeholder="Enter your phone number"
                  />
                ) : (
                  <p className="text-xl font-medium text-gray-100">{profileData.phone || 'Not specified'}</p>
                )}
              </div>

              {/* Customer ID */}
              <div className="bg-gradient-to-br from-blue-900/20 to-blue-800/20 p-6 rounded-xl border border-blue-500/30 hover:border-blue-400/50 transition-all duration-300">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-blue-500/30 rounded-lg flex items-center justify-center">
                    <Shield className="w-5 h-5 text-blue-300" />
                  </div>
                  <h3 className="text-lg font-semibold text-white">Customer ID</h3>
                </div>
                <p className="text-2xl font-bold text-blue-300 font-mono tracking-wider">
                  {customerData?.bpvc_code || `BPVC${customerData?.id?.slice(-4)?.toUpperCase() || '001'}`}
                </p>
              </div>

              {/* Member Since */}
              <div className="bg-gradient-to-br from-slate-700/30 to-slate-800/30 p-6 rounded-xl border border-slate-600/30 hover:border-slate-500/50 transition-all duration-300">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-orange-500/20 rounded-lg flex items-center justify-center">
                    <Calendar className="w-5 h-5 text-orange-400" />
                  </div>
                  <h3 className="text-lg font-semibold text-white">Member Since</h3>
                </div>
                <p className="text-xl font-medium text-gray-100">{memberSince}</p>
              </div>

              {/* Status */}
              <div className="bg-gradient-to-br from-green-900/20 to-emerald-800/20 p-6 rounded-xl border border-green-500/30 hover:border-green-400/50 transition-all duration-300">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-green-500/30 rounded-lg flex items-center justify-center">
                    <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
                  </div>
                  <h3 className="text-lg font-semibold text-white">Account Status</h3>
                </div>
                <div className="flex items-center gap-3">
                  <div className="px-4 py-2 bg-green-500/20 border border-green-400/30 rounded-full">
                    <span className="text-green-300 font-bold text-lg">● ACTIVE</span>
                  </div>
                  <span className="text-green-400 text-sm font-medium">Verified Account</span>
                </div>
              </div>

              {/* Saving Plan */}
              <div className="bg-gradient-to-br from-yellow-900/20 to-orange-800/20 p-6 rounded-xl border border-yellow-500/30 hover:border-yellow-400/50 transition-all duration-300">
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-10 h-10 bg-yellow-500/30 rounded-lg flex items-center justify-center">
                    <TrendingUp className="w-5 h-5 text-yellow-300" />
                  </div>
                  <h3 className="text-lg font-semibold text-white">Saving Plan</h3>
                </div>
                <div className="space-y-2">
                  {isEditing ? (
                    <select
                      value={editData.saving}
                      onChange={(e) => handleInputChange('saving', e.target.value)}
                      className="w-full px-4 py-3 bg-slate-800/50 border border-slate-600 rounded-lg text-white focus:border-yellow-500 focus:outline-none"
                    >
                      <option value="">Select Saving Plan</option>
                      <option value="starter">Starter Plan - ₹10,000</option>
                      <option value="growth">Growth Plan - ₹25,000</option>
                      <option value="premium">Premium Plan - ₹50,000</option>
                      <option value="elite">Elite Plan - ₹1,00,000</option>
                      <option value="platinum">Platinum Plan - ₹2,50,000</option>
                    </select>
                  ) : (
                    <>
                      {profileData.saving ? (
                        <>
                          <div className="px-4 py-2 bg-yellow-500/20 border border-yellow-400/30 rounded-full">
                            <span className="text-yellow-300 font-bold text-lg capitalize">
                              {profileData.saving.replace('_', ' ')} Plan
                            </span>
                          </div>
                          <p className="text-yellow-400 text-sm font-medium">
                            {profileData.saving === 'starter' && '₹10,000 Saving'}
                            {profileData.saving === 'growth' && '₹25,000 Saving'}
                            {profileData.saving === 'premium' && '₹50,000 Saving'}
                            {profileData.saving === 'elite' && '₹1,00,000 Saving'}
                            {profileData.saving === 'platinum' && '₹2,50,000 Saving'}
                          </p>
                        </>
                      ) : (
                        <div className="px-4 py-2 bg-gray-500/20 border border-gray-400/30 rounded-full">
                          <span className="text-gray-300 font-medium">No Plan Selected</span>
                        </div>
                      )}
                    </>
                  )}
                </div>
              </div>

            </div>

          </UnifiedCard>

          {/* Saving Summary */}
          <UnifiedCard className="p-8">
            <h2 className="text-2xl font-bold text-white mb-6">Saving Summary</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              
              <div className="text-center p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
                <p className="text-blue-400 text-sm font-medium">Total Saved</p>
                <p className="text-2xl font-bold text-white">₹{savingData.totalSaved.toLocaleString()}</p>
              </div>
              
              <div className="text-center p-4 bg-green-500/10 border border-green-500/30 rounded-lg">
                <p className="text-green-400 text-sm font-medium">Total Returns</p>
                <p className="text-2xl font-bold text-white">₹{savingData.totalReturns.toLocaleString()}</p>
              </div>
              
              <div className="text-center p-4 bg-purple-500/10 border border-purple-500/30 rounded-lg">
                <p className="text-purple-400 text-sm font-medium">Active Savings</p>
                <p className="text-2xl font-bold text-white">{savingData.activeSavings}</p>
              </div>
              
            </div>
          </UnifiedCard>

        </div>
      </div>
      <Footer />
    </UnifiedBackground>
  );
}

export default CustomerProfile;
