// Application constants

export const USER_ROLES = {
  ADMIN: 'admin',
  PROMOTER: 'promoter',
  CUSTOMER: 'customer'
};

export const STORAGE_KEYS = {
  USER: 'user',
  THEME: 'theme'
};

export const SUPABASE_TABLES = {
  PROFILES: 'profiles',
  PROMOTERS: 'promoters',
  CUSTOMERS: 'customers',
  SAVINGS: 'savings',
  VENTURES: 'ventures'
};

export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  INTERNAL_SERVER_ERROR: 500
};

export const MESSAGES = {
  SUCCESS: {
    LOGIN: 'Login successful',
    LOGOUT: 'Logout successful',
    REGISTER: 'Registration successful',
    UPDATE: 'Updated successfully',
    DELETE: 'Deleted successfully',
    CREATE: 'Created successfully'
  },
  ERROR: {
    GENERIC: 'Something went wrong. Please try again.',
    NETWORK: 'Network error. Please check your connection.',
    UNAUTHORIZED: 'You are not authorized to perform this action.',
    VALIDATION: 'Please check your input and try again.',
    NOT_FOUND: 'The requested resource was not found.'
  }
};

export const ROUTES = {
  HOME: '/',
  LOGIN: '/login',
  REGISTER: '/register',
  DASHBOARD: '/dashboard',
  ADMIN: {
    DASHBOARD: '/admin/dashboard',
    USERS: '/admin/users',
    PROMOTERS: '/admin/promoters',
    CUSTOMERS: '/admin/customers',
    REPORTS: '/admin/reports'
  },
  PROMOTER: {
    DASHBOARD: '/promoter/dashboard',
    CUSTOMERS: '/promoter/customers',
    PAYMENTS: '/promoter/payments',
    REPORTS: '/promoter/reports'
  },
  CUSTOMER: {
    DASHBOARD: '/customer',
    SAVINGS: '/customer/savings',
    OPPORTUNITIES: '/customer/opportunities',
    PROFILE: '/customer/profile'
  }
};
