import React, { useState, useEffect } from 'react';
import { useAuth } from '../../common/context/AuthContext';
import { db } from "../../common/services/supabaseClient"
import { 
  UnifiedCard, 
  UnifiedButton,
  useScrollAnimation
} from "../../common/components/SharedTheme";
import { 
  User, 
  Mail, 
  Phone, 
  Building, 
  Tag, 
  Users, 
  Award, 
  Edit,
  Loader,
  CheckCircle,
  Clock,
  XCircle
} from 'lucide-react';

function PromoterProfile() {
  const { user } = useAuth();
  const [promoterData, setPromoterData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  useScrollAnimation();

  useEffect(() => {
    if (user && user.role === 'promoter') {
      loadPromoterData();
    }
  }, [user]);

  const loadPromoterData = async () => {
    try {
      setLoading(true);
      const { data, error } = await db.promoters.getById(user.id);
      if (error) {
        throw error;
      }
      setPromoterData(data);
    } catch (error) {
      console.error('Error loading promoter data:', error);
      setError('Failed to load promoter data. Please ensure your profile is set up in the database.');
    } finally {
      setLoading(false);
    }
  };

  const getVerificationStatusColor = (status) => {
    switch (status) {
      case 'verified':
        return 'text-green-400';
      case 'pending':
        return 'text-yellow-400';
      case 'rejected':
        return 'text-red-400';
      default:
        return 'text-gray-400';
    }
  };

  const getVerificationStatusIcon = (status) => {
    switch (status) {
      case 'verified':
        return <CheckCircle className="w-5 h-5" />;
      case 'pending':
        return <Clock className="w-5 h-5" />;
      case 'rejected':
        return <XCircle className="w-5 h-5" />;
      default:
        return <Clock className="w-5 h-5" />;
    }
  };

  if (loading) {
    return (
      <UnifiedCard className="p-8">
        <div className="flex items-center justify-center">
          <Loader className="w-8 h-8 text-orange-400 animate-spin mr-3" />
          <span className="text-white">Loading promoter profile...</span>
        </div>
      </UnifiedCard>
    );
  }

  if (error) {
    return (
      <UnifiedCard className="p-8">
        <div className="text-center text-red-400">
          <XCircle className="w-12 h-12 mx-auto mb-4" />
          <p>{error}</p>
        </div>
      </UnifiedCard>
    );
  }

  if (!promoterData) {
    return (
      <UnifiedCard className="p-8">
        <div className="text-center text-gray-400">
          <User className="w-12 h-12 mx-auto mb-4" />
          <p>No promoter data found</p>
        </div>
      </UnifiedCard>
    );
  }

  return (
    <div className="space-y-6" data-animate>
      {/* Profile Header */}
      <UnifiedCard className="p-6">
        <div className="flex items-start justify-between mb-6">
          <div className="flex items-center space-x-4">
            <div className="w-16 h-16 bg-gradient-to-r from-orange-400 to-yellow-500 rounded-full flex items-center justify-center">
              <User className="w-8 h-8 text-white" />
            </div>
            <div>
              <h2 className="text-2xl font-bold text-white">{promoterData.name}</h2>
              <p className="text-gray-400">{promoterData.email}</p>
              <div className={`flex items-center mt-2 ${getVerificationStatusColor(promoterData.promoterData?.verificationStatus)}`}>
                {getVerificationStatusIcon(promoterData.promoterData?.verificationStatus)}
                <span className="ml-2 text-sm font-medium">
                  {promoterData.promoterData?.verificationStatus?.charAt(0).toUpperCase() + 
                   promoterData.promoterData?.verificationStatus?.slice(1) || 'Pending'}
                </span>
              </div>
            </div>
          </div>
          <UnifiedButton className="flex items-center space-x-2">
            <Edit className="w-4 h-4" />
            <span>Edit Profile</span>
          </UnifiedButton>
        </div>

        {/* Quick Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-gray-700/50 rounded-lg p-4 text-center">
            <Award className="w-6 h-6 text-orange-400 mx-auto mb-2" />
            <p className="text-2xl font-bold text-white">{promoterData.promoterData?.level || 1}</p>
            <p className="text-sm text-gray-400">Level</p>
          </div>
          <div className="bg-gray-700/50 rounded-lg p-4 text-center">
            <Users className="w-6 h-6 text-blue-400 mx-auto mb-2" />
            <p className="text-2xl font-bold text-white">{promoterData.promoterData?.totalCustomers || 0}</p>
            <p className="text-sm text-gray-400">Customers</p>
          </div>
          <div className="bg-gray-700/50 rounded-lg p-4 text-center">
            <Tag className="w-6 h-6 text-green-400 mx-auto mb-2" />
            <p className="text-2xl font-bold text-white">{promoterData.promoterData?.pins || 0}</p>
            <p className="text-sm text-gray-400">Pins</p>
          </div>
          <div className="bg-gray-700/50 rounded-lg p-4 text-center">
            <Award className="w-6 h-6 text-purple-400 mx-auto mb-2" />
            <p className="text-2xl font-bold text-white">₹{(promoterData.promoterData?.totalEarnings || 0).toLocaleString()}</p>
            <p className="text-sm text-gray-400">Earnings</p>
          </div>
        </div>
      </UnifiedCard>

      {/* Business Information */}
      <UnifiedCard className="p-6">
        <h3 className="text-xl font-bold text-white mb-6 flex items-center">
          <Building className="w-5 h-5 mr-2" />
          Business Information
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Business Name</label>
            <p className="text-white">{promoterData.promoterData?.businessName || 'Not provided'}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Category</label>
            <p className="text-white">{promoterData.promoterData?.businessCategory || 'Not specified'}</p>
          </div>
          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-gray-400 mb-2">Description</label>
            <p className="text-white">{promoterData.promoterData?.businessDescription || 'No description provided'}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Referral Code</label>
            <div className="flex items-center space-x-2">
              <code className="bg-gray-700 px-3 py-1 rounded text-orange-400 font-mono">
                {promoterData.promoterData?.referralCode || 'Not generated'}
              </code>
              <UnifiedButton size="sm">Copy</UnifiedButton>
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Commission Rate</label>
            <p className="text-white">{promoterData.promoterData?.commissionRate || 5}%</p>
          </div>
        </div>
      </UnifiedCard>

      {/* Contact Information */}
      <UnifiedCard className="p-6">
        <h3 className="text-xl font-bold text-white mb-6 flex items-center">
          <Mail className="w-5 h-5 mr-2" />
          Contact Information
        </h3>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="flex items-center space-x-3">
            <Mail className="w-5 h-5 text-gray-400" />
            <div>
              <p className="text-sm text-gray-400">Email</p>
              <p className="text-white">{promoterData.email}</p>
            </div>
          </div>
          <div className="flex items-center space-x-3">
            <Phone className="w-5 h-5 text-gray-400" />
            <div>
              <p className="text-sm text-gray-400">Phone</p>
              <p className="text-white">{promoterData.phone}</p>
            </div>
          </div>
        </div>
      </UnifiedCard>

      {/* Hierarchy Information */}
      {promoterData.promoterData?.parentPromoter && (
        <UnifiedCard className="p-6">
          <h3 className="text-xl font-bold text-white mb-6 flex items-center">
            <Users className="w-5 h-5 mr-2" />
            Hierarchy
          </h3>
          
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-r from-blue-400 to-purple-500 rounded-full flex items-center justify-center">
              <User className="w-5 h-5 text-white" />
            </div>
            <div>
              <p className="text-sm text-gray-400">Parent Promoter</p>
              <p className="text-white font-medium">{promoterData.promoterData.parentPromoter.name}</p>
              <p className="text-sm text-gray-400">{promoterData.promoterData.parentPromoter.email}</p>
            </div>
          </div>
        </UnifiedCard>
      )}
    </div>
  );
}

export default PromoterProfile;
