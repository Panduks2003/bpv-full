# 🚀 BrightPlanet Ventures - Backend Product Specification Document

## 📋 Executive Summary

**BrightPlanet Ventures Backend** is a comprehensive serverless backend system built on **Supabase (PostgreSQL)** that powers a multi-role investment promotion platform. The backend provides robust APIs, real-time capabilities, automated business logic, and secure data management for administrators, promoters, and customers.

### 🎯 Backend Vision
To deliver a scalable, secure, and performant backend infrastructure that supports complex business operations including multi-level commission distribution, PIN management, real-time synchronization, and comprehensive audit trails while maintaining data integrity and security.

---

## 🏗️ Backend Architecture

### Technology Stack
- **Database**: PostgreSQL (via Supabase)
- **Backend-as-a-Service**: Supabase
- **Authentication**: Supabase Auth with JWT tokens
- **Real-time**: Supabase Realtime (WebSocket connections)
- **API Layer**: Supabase REST API + Custom PostgreSQL Functions
- **Security**: Row Level Security (RLS) policies
- **Triggers**: PostgreSQL triggers for automated business logic
- **Functions**: PL/pgSQL stored procedures for complex operations

### Architecture Patterns
- **Serverless Architecture**: No server management required
- **Event-Driven**: Database triggers for automated processes
- **Real-time Synchronization**: WebSocket-based live updates
- **Microservices Pattern**: Modular function-based services
- **CQRS Pattern**: Separate read/write operations for performance

---

## 🗄️ Database Schema & Data Model

### Core Tables

#### 1. **profiles** (Central User Table)
```sql
- id (UUID, Primary Key)
- email (VARCHAR, Unique)
- name (VARCHAR)
- phone (VARCHAR)
- role (ENUM: admin, promoter, customer)
- promoter_id (VARCHAR, Unique for promoters)
- customer_id (VARCHAR, Unique for customers)
- parent_promoter_id (UUID, Foreign Key)
- role_level (VARCHAR, Default: 'Affiliate')
- status (VARCHAR, Default: 'Active')
- address (TEXT)
- pins (INTEGER, Default: 0)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 2. **pin_transactions** (PIN Management)
```sql
- id (UUID, Primary Key)
- transaction_id (VARCHAR, Unique)
- user_id (UUID, Foreign Key)
- action_type (ENUM: customer_creation, admin_allocation, admin_deduction)
- pin_change_value (INTEGER)
- balance_before (INTEGER)
- balance_after (INTEGER)
- note (TEXT, Auto-generated)
- created_by (UUID, Foreign Key)
- related_entity_id (UUID)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 3. **affiliate_commissions** (Commission System)
```sql
- id (SERIAL, Primary Key)
- customer_id (UUID, Foreign Key)
- initiator_promoter_id (UUID, Foreign Key)
- recipient_id (UUID, Foreign Key)
- recipient_type (ENUM: promoter, admin)
- level (INTEGER, 1-4)
- amount (DECIMAL)
- status (ENUM: pending, credited, failed)
- transaction_id (VARCHAR, Unique)
- note (TEXT)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 4. **promoter_wallet** (Wallet Management)
```sql
- promoter_id (UUID, Primary Key)
- balance (DECIMAL, Default: 0)
- total_earned (DECIMAL, Default: 0)
- total_withdrawn (DECIMAL, Default: 0)
- commission_count (INTEGER, Default: 0)
- last_commission_at (TIMESTAMP)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 5. **admin_wallet** (Admin Wallet)
```sql
- admin_id (UUID, Primary Key)
- balance (DECIMAL, Default: 0)
- total_commission_received (DECIMAL, Default: 0)
- unclaimed_commissions (DECIMAL, Default: 0)
- commission_count (INTEGER, Default: 0)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 6. **withdrawal_requests** (Withdrawal Management)
```sql
- id (UUID, Primary Key)
- request_id (VARCHAR, Unique)
- promoter_id (UUID, Foreign Key)
- amount (DECIMAL)
- status (ENUM: pending, approved, rejected, processed)
- bank_details (JSONB)
- admin_notes (TEXT)
- processed_by (UUID, Foreign Key)
- processed_at (TIMESTAMP)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Supporting Tables
- **promoter_id_sequence**: Auto-incrementing promoter IDs
- **transaction_counters**: Sequential transaction ID generation
- **pin_requests**: PIN request management
- **customers**: Customer-specific data
- **promoters**: Promoter-specific business data

---

## 🔧 Core Backend Services

### 1. **Authentication & Authorization Service**

#### Multi-Method Login Support
- **Email/Password**: Standard authentication
- **Promoter ID**: BPVP01, BPVP02 format
- **Customer ID**: BPVC01, BPVC02 format
- **Phone Number**: 10-digit mobile numbers

#### Security Features
- **JWT Token Management**: Secure session handling
- **Row Level Security**: Database-level access control
- **Role-Based Access**: Admin, Promoter, Customer permissions
- **Session Persistence**: Automatic token refresh
- **Password Security**: Supabase Auth encryption

#### API Endpoints
```javascript
// Authentication endpoints
POST /auth/signup - User registration
POST /auth/signin - Multi-method login
POST /auth/signout - Session termination
GET /auth/user - Current user info
POST /auth/reset-password - Password reset
```

### 2. **PIN Management Service**

#### Core Functions
- **execute_pin_transaction()**: Central PIN operation handler
- **deduct_pin_for_customer_creation()**: Automatic PIN deduction
- **admin_allocate_pins()**: Admin PIN distribution
- **admin_deduct_pins()**: Admin PIN removal

#### Business Logic
- **Automatic Deduction**: 1 PIN per customer creation
- **Balance Validation**: Prevents negative balances
- **Transaction Logging**: Complete audit trail
- **Real-time Updates**: Live balance synchronization

#### API Operations
```javascript
// PIN management endpoints
POST /rpc/execute_pin_transaction - Execute PIN transaction
POST /rpc/deduct_pin_for_customer_creation - Customer creation deduction
POST /rpc/admin_allocate_pins - Admin PIN allocation
POST /rpc/admin_deduct_pins - Admin PIN deduction
GET /pin_transactions - Get transaction history
GET /profiles/{id}/pins - Get current balance
```

### 3. **Commission Distribution Service**

#### Multi-Level Commission System
- **Level 1**: Creator promoter - ₹500
- **Level 2**: Parent promoter - ₹100
- **Level 3**: Grandparent promoter - ₹100
- **Level 4**: Great-grandparent promoter - ₹100
- **Admin Fallback**: Unclaimed commissions

#### Automated Distribution
- **Trigger-Based**: Automatic on customer creation
- **Hierarchy Validation**: Ensures valid promoter relationships
- **Wallet Updates**: Real-time balance synchronization
- **Transaction Tracking**: Complete commission audit trail

#### Core Functions
```sql
-- Commission distribution function
distribute_affiliate_commission(customer_id, initiator_promoter_id)

-- Commission summary functions
get_promoter_commission_summary(promoter_id)
get_admin_commission_summary()

-- Wallet management functions
update_promoter_wallet(promoter_id, amount, operation)
update_admin_wallet(amount, operation)
```

### 4. **Promoter Management Service**

#### Unified Promoter System
- **Auto-Generated IDs**: BPVP01, BPVP02, etc.
- **Hierarchical Structure**: Parent-child relationships
- **Role Management**: Affiliate, Manager, Director levels
- **Status Control**: Active/Inactive management

#### Core Functions
```sql
-- Promoter creation and management
create_unified_promoter(name, email, password, phone, address, parent_id)
update_promoter_profile(promoter_id, updates)
generate_next_promoter_id()

-- Hierarchy management
get_promoter_hierarchy(promoter_id)
validate_promoter_hierarchy(promoter_id, parent_id)
```

#### API Operations
```javascript
// Promoter management endpoints
POST /rpc/create_unified_promoter - Create new promoter
PUT /rpc/update_promoter_profile - Update promoter
GET /rpc/get_promoter_hierarchy - Get hierarchy tree
GET /profiles?role=promoter - List all promoters
```

### 5. **Customer Management Service**

#### Customer Lifecycle
- **Creation**: Promoter-initiated customer registration
- **Profile Management**: Personal information updates
- **Investment Tracking**: Portfolio and savings management
- **Commission Attribution**: Source tracking for commissions

#### Core Functions
```sql
-- Customer management
create_customer_with_commission(promoter_id, customer_data)
update_customer_profile(customer_id, updates)
get_customer_by_promoter(promoter_id)
```

### 6. **Withdrawal Management Service**

#### Withdrawal Process
- **Request Submission**: Promoter withdrawal requests
- **Admin Review**: Approval/rejection workflow
- **Bank Integration**: Payment processing
- **Status Tracking**: Complete audit trail

#### Core Functions
```sql
-- Withdrawal management
create_withdrawal_request(promoter_id, amount, bank_details)
process_withdrawal_request(request_id, admin_id, status, notes)
get_withdrawal_history(promoter_id)
```

---

## 🔄 Real-Time Capabilities

### WebSocket Subscriptions

#### PIN Balance Updates
```javascript
// Real-time PIN balance changes
supabase
  .channel('pin-balance-changes')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'pin_transactions',
    filter: `user_id=eq.${userId}`
  }, callback)
```

#### Commission Updates
```javascript
// Real-time commission notifications
supabase
  .channel('commission-updates')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'affiliate_commissions',
    filter: `recipient_id=eq.${promoterId}`
  }, callback)
```

#### Withdrawal Status Updates
```javascript
// Real-time withdrawal status changes
supabase
  .channel('withdrawal-updates')
  .on('postgres_changes', {
    event: 'UPDATE',
    schema: 'public',
    table: 'withdrawal_requests',
    filter: `promoter_id=eq.${promoterId}`
  }, callback)
```

### Performance Optimizations
- **Event Throttling**: 10 events per second limit
- **Selective Subscriptions**: Role-based channel access
- **Connection Pooling**: Efficient WebSocket management
- **Automatic Cleanup**: Subscription lifecycle management

---

## 🔒 Security & Access Control

### Row Level Security (RLS) Policies

#### Admin Access Policies
```sql
-- Admins can view all data
CREATE POLICY "admin_full_access" ON profiles
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'admin'
  )
);
```

#### Promoter Access Policies
```sql
-- Promoters can view their own data and sub-promoters
CREATE POLICY "promoter_limited_access" ON profiles
FOR SELECT USING (
  id = auth.uid() OR 
  parent_promoter_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'promoter'
  )
);
```

#### Customer Access Policies
```sql
-- Customers can only view their own data
CREATE POLICY "customer_own_data" ON profiles
FOR SELECT USING (
  id = auth.uid() AND role = 'customer'
);
```

### Data Encryption
- **In Transit**: HTTPS/TLS encryption
- **At Rest**: Supabase database encryption
- **Sensitive Fields**: Additional encryption for PII
- **API Keys**: Secure environment variable management

### Audit Trail
- **Transaction Logging**: All PIN operations logged
- **Commission Tracking**: Complete distribution history
- **User Actions**: Login, logout, and modification tracking
- **Admin Actions**: All administrative operations logged

---

## 📊 Business Logic & Rules

### PIN Management Rules
1. **Customer Creation**: Automatic deduction of 1 PIN
2. **Admin Allocation**: Positive PIN addition
3. **Admin Deduction**: Negative PIN removal
4. **Balance Validation**: No negative balances allowed
5. **Transaction ID**: Unique BPV transaction identifiers

### Commission Distribution Rules
1. **Total Commission**: ₹800 per customer
2. **Level 1**: ₹500 to creator promoter
3. **Levels 2-4**: ₹100 each to parent promoters
4. **Admin Fallback**: Unclaimed amounts to admin wallet
5. **Automatic Distribution**: Triggered on customer creation

### Promoter Hierarchy Rules
1. **Maximum Levels**: 4 levels deep
2. **Circular Prevention**: No circular references
3. **Parent Validation**: Valid parent-child relationships
4. **Commission Inheritance**: Upward commission flow
5. **Status Management**: Active/Inactive status control

### Withdrawal Rules
1. **Minimum Amount**: Configurable minimum withdrawal
2. **Available Balance**: Cannot exceed wallet balance
3. **Admin Approval**: All withdrawals require approval
4. **Processing Time**: Configurable processing timeframe
5. **Bank Validation**: Valid bank account requirements

---

## 🚀 Performance & Scalability

### Database Performance
- **Indexing Strategy**: Optimized indexes on frequently queried columns
- **Query Optimization**: Efficient JOIN operations
- **Connection Pooling**: Supabase managed connections
- **Caching**: Supabase edge caching for static data

### API Performance
- **Response Times**: < 500ms for standard operations
- **Concurrent Users**: Support for 1000+ simultaneous users
- **Rate Limiting**: Built-in Supabase rate limiting
- **Error Handling**: Comprehensive error management

### Scalability Features
- **Horizontal Scaling**: Supabase auto-scaling
- **Database Sharding**: Future-ready architecture
- **CDN Integration**: Global content delivery
- **Load Balancing**: Automatic load distribution

---

## 🔧 API Documentation

### Authentication Endpoints
```javascript
// User registration
POST /auth/v1/signup
{
  "email": "user@example.com",
  "password": "securepassword",
  "options": {
    "data": {
      "name": "John Doe",
      "role": "promoter"
    }
  }
}

// Multi-method login
POST /auth/v1/token?grant_type=password
{
  "email": "user@example.com", // or promoter_id, customer_id, phone
  "password": "securepassword"
}
```

### PIN Management Endpoints
```javascript
// Execute PIN transaction
POST /rest/v1/rpc/execute_pin_transaction
{
  "p_user_id": "uuid",
  "p_action_type": "admin_allocation",
  "p_pin_change_value": 10,
  "p_created_by": "admin-uuid"
}

// Get PIN transactions
GET /rest/v1/pin_transactions?user_id=eq.uuid&order=created_at.desc
```

### Commission Endpoints
```javascript
// Distribute commission
POST /rest/v1/rpc/distribute_affiliate_commission
{
  "p_customer_id": "uuid",
  "p_initiator_promoter_id": "uuid"
}

// Get commission summary
POST /rest/v1/rpc/get_promoter_commission_summary
{
  "p_promoter_id": "uuid"
}
```

### Promoter Management Endpoints
```javascript
// Create promoter
POST /rest/v1/rpc/create_unified_promoter
{
  "p_name": "John Doe",
  "p_email": "john@example.com",
  "p_password": "password",
  "p_phone": "9876543210",
  "p_parent_promoter_id": "uuid"
}

// Get promoters
GET /rest/v1/profiles?role=eq.promoter&select=*
```

---

## 📈 Monitoring & Analytics

### Performance Metrics
- **API Response Times**: Average response time tracking
- **Database Performance**: Query execution time monitoring
- **Error Rates**: Application error frequency
- **User Activity**: Active users and session metrics
- **Real-time Connections**: WebSocket connection monitoring

### Business Metrics
- **Commission Distribution**: Total commissions paid
- **PIN Usage**: PIN consumption patterns
- **Customer Acquisition**: New customer registration rates
- **Withdrawal Processing**: Withdrawal approval times
- **User Engagement**: Feature usage statistics

### Health Monitoring
- **Database Health**: Connection and query performance
- **API Health**: Endpoint availability and response times
- **Real-time Health**: WebSocket connection stability
- **Authentication Health**: Login success rates
- **Error Tracking**: Comprehensive error logging

---

## 🔄 Data Synchronization

### Real-time Updates
- **PIN Balance Changes**: Live balance updates
- **Commission Credits**: Instant commission notifications
- **Withdrawal Status**: Real-time status updates
- **User Activity**: Live user presence tracking
- **System Notifications**: Real-time alerts

### Data Consistency
- **ACID Compliance**: Database transaction integrity
- **Eventual Consistency**: Real-time synchronization
- **Conflict Resolution**: Automatic conflict handling
- **Data Validation**: Input validation and sanitization
- **Backup Strategy**: Automated data backups

---

## 🛠️ Development & Deployment

### Development Environment
- **Local Development**: Supabase CLI for local development
- **Database Migrations**: Version-controlled schema changes
- **Function Testing**: Unit testing for stored procedures
- **API Testing**: Comprehensive endpoint testing
- **Performance Testing**: Load testing and optimization

### Production Deployment
- **Supabase Hosting**: Managed backend infrastructure
- **Environment Management**: Separate dev/staging/prod environments
- **Database Backups**: Automated backup and recovery
- **Monitoring**: Real-time performance monitoring
- **Scaling**: Automatic scaling based on demand

### Maintenance
- **Regular Updates**: Supabase platform updates
- **Security Patches**: Timely security updates
- **Performance Optimization**: Continuous performance tuning
- **Data Archiving**: Historical data management
- **Disaster Recovery**: Comprehensive recovery procedures

---

## 🎯 Success Metrics & KPIs

### Technical KPIs
- **Uptime**: 99.9% availability target
- **Response Time**: < 500ms average API response
- **Error Rate**: < 0.1% error rate
- **Concurrent Users**: Support 1000+ simultaneous users
- **Data Consistency**: 100% transaction integrity

### Business KPIs
- **Commission Accuracy**: 100% accurate distribution
- **PIN Management**: Zero PIN balance discrepancies
- **User Satisfaction**: High user satisfaction scores
- **System Reliability**: Minimal downtime incidents
- **Data Security**: Zero security breaches

---

## 🚀 Future Enhancements

### Phase 1: Advanced Features
- **Advanced Analytics**: Machine learning insights
- **Payment Integration**: Direct payment processing
- **Mobile API**: Dedicated mobile API endpoints
- **Advanced Reporting**: Comprehensive reporting system
- **API Versioning**: Versioned API management

### Phase 2: Scalability
- **Microservices**: Service decomposition
- **Event Sourcing**: Event-driven architecture
- **CQRS Implementation**: Command Query Responsibility Segregation
- **Advanced Caching**: Redis integration
- **Load Balancing**: Advanced load distribution

### Phase 3: Enterprise Features
- **Multi-tenancy**: Multi-organization support
- **Advanced Security**: Enterprise security features
- **Compliance**: Regulatory compliance features
- **Integration**: Third-party system integration
- **Customization**: Configurable business rules

---

## 🎉 Conclusion

The BrightPlanet Ventures Backend provides a robust, scalable, and secure foundation for the investment promotion platform. With its comprehensive API layer, real-time capabilities, automated business logic, and strong security measures, it delivers enterprise-grade functionality while maintaining simplicity and reliability.

The backend's modular architecture, comprehensive audit trails, and real-time synchronization capabilities ensure that all stakeholders have access to accurate, up-to-date information while maintaining data integrity and security. The system is designed to scale with business growth while providing the flexibility to adapt to changing requirements.

**The backend is production-ready and provides a complete solution for investment promotion, customer management, commission tracking, and PIN management with modern serverless technologies and best practices.**
