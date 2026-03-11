/**
 * Zippa Admin Panel - Main Application Logic (SPA Router & API)
 */

const API_BASE = '/api';

const state = {
    user: null,
    token: localStorage.getItem('zippa_admin_token'),
    currentPage: 'dashboard'
};

// ============================================
// API CLIENT
// ============================================

const api = {
    async request(endpoint, options = {}) {
        const headers = {
            'Content-Type': 'application/json',
            ...(state.token && { 'Authorization': `Bearer ${state.token}` })
        };

        try {
            const response = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
            const data = await response.json();

            if (response.status === 401 || response.status === 403) {
                // Token expired or not authorized
                this.logout();
                return null;
            }

            return data;
        } catch (err) {
            console.error('API Request Error:', err);
            return { success: false, message: 'Network error' };
        }
    },

    get(endpoint) { return this.request(endpoint, { method: 'GET' }); },
    post(endpoint, body) { return this.request(endpoint, { method: 'POST', body: JSON.stringify(body) }); },
    put(endpoint, body) { return this.request(endpoint, { method: 'PUT', body: JSON.stringify(body) }); },
    delete(endpoint) { return this.request(endpoint, { method: 'DELETE' }); },

    logout() {
        localStorage.removeItem('zippa_admin_token');
        state.token = null;
        state.user = null;
        document.getElementById('login-overlay').classList.remove('hidden');
    }
};

// ============================================
// ROUTER
// ============================================

const routes = {
    'dashboard': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = '<div class="loading-state"><div class="spinner"></div><span>Loading Stats...</span></div>';
        
        const data = await api.get('/admin/stats');
        if (!data || !data.success) return;

        const stats = data.stats;
        const totalUsers = stats.users.reduce((acc, u) => acc + parseInt(u.count), 0);
        const totalOrders = stats.orders.reduce((acc, o) => acc + parseInt(o.count), 0);

        content.innerHTML = `
            <h1 class="page-title">Dashboard Overview</h1>
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon blue"><i data-lucide="users"></i></div>
                        <span class="stat-trend positive">+12%</span>
                    </div>
                    <div class="stat-value">${totalUsers}</div>
                    <div class="stat-label">Total Users</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon purple"><i data-lucide="shopping-cart"></i></div>
                        <span class="stat-trend negative">-2%</span>
                    </div>
                    <div class="stat-value">${totalOrders}</div>
                    <div class="stat-label">Total Orders</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon green"><i data-lucide="circle-dollar-sign"></i></div>
                        <span class="stat-trend positive">+8%</span>
                    </div>
                    <div class="stat-value">₦${parseFloat(stats.finance.total_revenue).toLocaleString()}</div>
                    <div class="stat-label">Total Revenue</div>
                </div>
                <div class="stat-card">
                    <div class="stat-header">
                        <div class="stat-icon orange"><i data-lucide="lock"></i></div>
                    </div>
                    <div class="stat-value">₦${parseFloat(stats.finance.escrow_balance).toLocaleString()}</div>
                    <div class="stat-label">Pending Escrow</div>
                </div>
            </div>

            <div class="recent-grid">
                <div class="card recent-orders">
                    <div class="card-header">
                        <h2>Recent Deliveries</h2>
                        <button class="btn-text">View All</button>
                    </div>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Order #</th>
                                <th>Customer</th>
                                <th>Amount</th>
                                <th>Status</th>
                                <th>Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${stats.recentActivity.map(order => `
                                <tr>
                                    <td>#${order.order_number}</td>
                                    <td>${order.customer_name}</td>
                                    <td>₦${parseFloat(order.total_fare).toLocaleString()}</td>
                                    <td><span class="badge ${order.status}">${order.status}</span></td>
                                    <td>${new Date(order.created_at).toLocaleDateString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
        `;
        lucide.createIcons();
    },
    'users': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = '<div class="loading-state"><div class="spinner"></div><span>Loading Users...</span></div>';
        
        const data = await api.get('/admin/users');
        if (!data || !data.success) return;

        content.innerHTML = `
            <div class="header-row">
                <h1 class="page-title">User Management</h1>
                <div class="filter-group">
                    <select id="role-filter"><option value="">All Roles</option><option value="customer">Customer</option><option value="rider">Rider</option><option value="vendor">Vendor</option></select>
                </div>
            </div>
            <div class="card">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>User</th>
                            <th>Role</th>
                            <th>Phone</th>
                            <th>KYC Status</th>
                            <th>Joined</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.users.map(user => `
                            <tr>
                                <td>
                                    <div class="user-cell">
                                        <div class="initials">${user.full_name?.[0] || 'U'}</div>
                                        <div class="details">
                                            <span>${user.full_name}</span>
                                            <small>${user.email}</small>
                                        </div>
                                    </div>
                                </td>
                                <td><span class="role-badge ${user.role}">${user.role}</span></td>
                                <td>${user.phone || 'N/A'}</td>
                                <td><span class="kyc-badge ${user.kyc_status}">${user.kyc_status}</span></td>
                                <td>${new Date(user.created_at).toLocaleDateString()}</td>
                                <td><button class="icon-btn small"><i data-lucide="edit-3"></i></button></td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
        lucide.createIcons();
    },
    'orders': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = '<div class="loading-state"><div class="spinner"></div><span>Loading Orders...</span></div>';
        
        const data = await api.get('/admin/orders');
        if (!data || !data.success) return;

        content.innerHTML = `
            <h1 class="page-title">Order Management</h1>
            <div class="card">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Order #</th>
                            <th>Customer</th>
                            <th>Rider</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.orders.map(order => `
                            <tr>
                                <td>#${order.order_number}</td>
                                <td>${order.customer_name}</td>
                                <td>${order.rider_name || '<i>Assigning...</i>'}</td>
                                <td>₦${parseFloat(order.total_fare).toLocaleString()}</td>
                                <td><span class="badge ${order.status}">${order.status}</span></td>
                                <td>${new Date(order.created_at).toLocaleDateString()}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
        lucide.createIcons();
    },
    'finance': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = '<div class="loading-state"><div class="spinner"></div><span>Loading Financials...</span></div>';
        
        const data = await api.get('/admin/withdrawals');
        if (!data || !data.success) return;

        content.innerHTML = `
            <h1 class="page-title">Financial Review</h1>
            <div class="card">
                <div class="card-header"><h2>Pending Withdrawals</h2></div>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>User</th>
                            <th>Amount</th>
                            <th>Bank</th>
                            <th>Account</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.withdrawals.map(w => `
                            <tr>
                                <td>${w.full_name}</td>
                                <td>₦${parseFloat(w.amount).toLocaleString()}</td>
                                <td>${w.bank_name || 'N/A'}</td>
                                <td>${w.account_number || 'N/A'}</td>
                                <td><span class="badge ${w.status}">${w.status}</span></td>
                                <td><button class="btn-primary small">Review</button></td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
        lucide.createIcons();
    },
    'categories': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = '<div class="loading-state"><div class="spinner"></div><span>Loading Categories...</span></div>';
        
        const data = await api.get('/admin/categories');
        if (!data || !data.success) return;

        content.innerHTML = `
            <div class="header-row">
                <h1 class="page-title">Marketplace Categories</h1>
                <button class="btn-primary small">+ Add New</button>
            </div>
            <div class="grid-3">
                ${data.categories.map(cat => `
                    <div class="card cat-card">
                        <img src="${cat.image_url || '/placeholder.png'}" class="cat-img">
                        <div class="cat-info">
                            <h3>${cat.name}</h3>
                            <div class="cat-actions">
                                <button class="icon-btn small"><i data-lucide="edit-2"></i></button>
                                <button class="icon-btn small delete"><i data-lucide="trash-2"></i></button>
                            </div>
                        </div>
                    </div>
                `).join('')}
            </div>
        `;
        lucide.createIcons();
    },
    'kyc': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = '<div class="loading-state"><div class="spinner"></div><span>Loading KYC Requests...</span></div>';
        
        const data = await api.get('/admin/users?kyc_status=pending');
        if (!data || !data.success) return;

        content.innerHTML = `
            <h1 class="page-title">KYC Review Queue</h1>
            <div class="card">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>User</th>
                            <th>Role</th>
                            <th>Document Type</th>
                            <th>Submitted</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.users.map(user => `
                            <tr>
                                <td>${user.full_name} (${user.email})</td>
                                <td>${user.role}</td>
                                <td>Government ID</td>
                                <td>${new Date(user.created_at).toLocaleDateString()}</td>
                                <td>
                                    <button class="btn-primary small" onclick="reviewKYC('${user.id}', 'verified')">Approve</button>
                                    <button class="btn-primary small secondary" onclick="reviewKYC('${user.id}', 'rejected')">Reject</button>
                                </td>
                            </tr>
                        `).join('')}
                        ${data.users.length === 0 ? '<tr><td colspan="5" style="text-align:center; padding: 40px; color: var(--text-secondary);">No pending KYC requests</td></tr>' : ''}
                    </tbody>
                </table>
            </div>
        `;
        lucide.createIcons();
        window.reviewKYC = async (id, status) => {
            if (!confirm(`Are you sure you want to mark this user as ${status}?`)) return;
            const res = await api.put(`/admin/users/${id}/kyc`, { status });
            if (res.success) routes.kyc();
        };
    },
    'settings': () => {
        document.getElementById('page-content').innerHTML = `
            <div class="header-row">
                <h1 class="page-title">System Settings</h1>
                <div class="tab-group">
                    <button class="tab active">General</button>
                    <button class="tab" onclick="routes.notify()">Notifications</button>
                </div>
            </div>
            <div class="card settings-card">
                <div class="setting-item">
                    <div class="info">
                        <h3>Service Fee</h3>
                        <p>Platform percentage commission on every delivery</p>
                    </div>
                    <div class="action"><input type="number" value="10"> %</div>
                </div>
                <div class="setting-item">
                    <div class="info">
                        <h3>Minimum Withdrawal</h3>
                        <p>Lowest amount riders/vendors can withdraw</p>
                    </div>
                    <div class="action">₦ <input type="number" value="1000"></div>
                </div>
                <div class="setting-item">
                    <div class="info">
                        <h3>Surge Multiplier</h3>
                        <p>Global multiplier for delivery fares</p>
                    </div>
                    <div class="action"><input type="number" value="1.0" step="0.1"> x</div>
                </div>
                <div class="card-footer">
                    <button class="btn-primary">Save Changes</button>
                </div>
            </div>
        `;
        lucide.createIcons();
    },
    'notify': () => {
        document.getElementById('page-content').innerHTML = `
            <h1 class="page-title">Push Notification Center</h1>
            <div class="card settings-card">
                <div class="card-header"><h2>Broadcast Message</h2></div>
                <div class="p-24">
                    <div class="form-group">
                        <label>Target Audience</label>
                        <select class="form-select"><option>All Users</option><option>Customers Only</option><option>Riders Only</option><option>Vendors Only</option></select>
                    </div>
                    <div class="form-group">
                        <label>Title</label>
                        <input type="text" placeholder="e.g. Weekend Promo!">
                    </div>
                    <div class="form-group">
                        <label>Message Content</label>
                        <textarea rows="4" placeholder="Type your notification message here..."></textarea>
                    </div>
                    <button class="btn-primary">Send Broadcast Now</button>
                </div>
            </div>
        `;
        lucide.createIcons();
    }
};

async function navigate() {
    const hash = window.location.hash.replace('#/', '') || 'dashboard';
    state.currentPage = hash;

    // Update Sidebar Navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.getAttribute('href') === `#/${hash}`);
    });

    if (routes[hash]) {
        await routes[hash]();
    }
}

// ============================================
// AUTHENTICATION
// ============================================

async function initAuth() {
    if (!state.token) {
        document.getElementById('login-overlay').classList.remove('hidden');
        return;
    }

    // Briefly check if token works by fetching stats
    const check = await api.get('/admin/stats');
    if (!check) return; // api.request handles logout on fail

    document.getElementById('login-overlay').classList.add('hidden');
    navigate();
}

document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;
    const errorEl = document.getElementById('login-error');

    errorEl.classList.add('hidden');
    
    try {
        const response = await fetch(`${API_BASE}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });
        const data = await response.json();

        if (data.success && data.user.role === 'admin') {
            state.token = data.token;
            state.user = data.user;
            localStorage.setItem('zippa_admin_token', data.token);
            
            // Update UI
            document.getElementById('admin-name').textContent = data.user.fullName;
            document.getElementById('admin-avatar-char').textContent = data.user.fullName[0].toUpperCase();
            
            document.getElementById('login-overlay').classList.add('hidden');
            navigate();
        } else {
            errorEl.textContent = data.message || 'Access denied. Admins only.';
            errorEl.classList.remove('hidden');
        }
    } catch (err) {
        errorEl.textContent = 'Login failed. Check your connection.';
        errorEl.classList.remove('hidden');
    }
});

document.getElementById('logout-btn').addEventListener('click', () => {
    api.logout();
});

// Init
window.addEventListener('hashchange', navigate);
window.addEventListener('load', initAuth);

lucide.createIcons();
