/**
 * Zippa Admin V2 - Premium Glassmorphism Logic
 */

const API_BASE = '/api';

const state = {
    user: null,
    token: localStorage.getItem('zippa_admin_token'),
    currentPage: 'dashboard',
    stats: null,
    searchQuery: ''
};

// ============================================
// API CLIENT (Enhanced)
// ============================================

const api = {
    async request(endpoint, options = {}) {
        const headers = {
            'Content-Type': 'application/json',
            ...(state.token && { 'Authorization': `Bearer ${state.token}` })
        };

        try {
            const response = await fetch(`${API_BASE}${endpoint}`, { ...options, headers });
            if (response.status === 401 || response.status === 403) {
                this.logout();
                return null;
            }
            return await response.json();
        } catch (err) {
            console.error('API Error:', err);
            return { success: false, message: 'Connection lost' };
        }
    },

    get(endpoint) { return this.request(endpoint, { method: 'GET' }); },
    post(endpoint, body) { return this.request(endpoint, { method: 'POST', body: JSON.stringify(body) }); },
    put(endpoint, body) { return this.request(endpoint, { method: 'PUT', body: JSON.stringify(body) }); },
    
    logout() {
        localStorage.removeItem('zippa_admin_token');
        state.token = null;
        document.getElementById('login-overlay').classList.remove('hidden');
    }
};

// ============================================
// UI COMPONENTS (Reusable)
// ============================================

const ui = {
    loader() {
        return `<div class="loading-state"><div class="spinner"></div><span>Synchronizing Data...</span></div>`;
    },
    badge(type, text) {
        return `<span class="badge ${type.toLowerCase()}">${text}</span>`;
    },
    currency(val) {
        return '₦' + parseFloat(val || 0).toLocaleString(undefined, { minimumFractionDigits: 2 });
    }
};

// ============================================
// PAGE ROUTER
// ============================================

const routes = {
    'dashboard': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = ui.loader();
        
        const data = await api.get('/admin/stats');
        if (!data?.success) return;
        state.stats = data.stats;

        const totalUsers = state.stats.users.reduce((acc, u) => acc + parseInt(u.count), 0);
        const totalOrders = state.stats.orders.reduce((acc, o) => acc + parseInt(o.count), 0);

        content.innerHTML = `
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon blue"><i data-lucide="users"></i></div>
                    <div class="stat-value">${totalUsers}</div>
                    <div class="stat-label">Total platform users</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon purple"><i data-lucide="package"></i></div>
                    <div class="stat-value">${totalOrders}</div>
                    <div class="stat-label">Orders processed</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon green"><i data-lucide="banknote"></i></div>
                    <div class="stat-value">${ui.currency(state.stats.finance.total_revenue)}</div>
                    <div class="stat-label">Revenue (Commission)</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon orange"><i data-lucide="shield-alert"></i></div>
                    <div class="stat-value">${ui.currency(state.stats.finance.escrow_balance)}</div>
                    <div class="stat-label">Funds in Escrow</div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <h2>Recent Deliveries</h2>
                    <button class="btn-primary small secondary" onclick="location.hash='#/orders'">View All</button>
                </div>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Order ID</th>
                            <th>Customer</th>
                            <th>Amount</th>
                            <th>Status</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${state.stats.recentActivity.map(order => `
                            <tr>
                                <td style="color: var(--accent-blue); font-weight: 600;">#${order.order_number}</td>
                                <td>${order.customer_name}</td>
                                <td>${ui.currency(order.total_fare)}</td>
                                <td>${ui.badge(order.status, order.status)}</td>
                                <td>${new Date(order.created_at).toLocaleDateString()}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
        lucide.createIcons();
    },

    'users': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = ui.loader();
        const data = await api.get(`/admin/users${state.searchQuery ? '?search='+state.searchQuery : ''}`);
        
        content.innerHTML = `
            <div class="header-row">
                <h1 class="page-title">User Directory</h1>
                <div class="tab-group">
                    <button class="tab active">All</button>
                    <button class="tab">Riders</button>
                    <button class="tab">Vendors</button>
                </div>
            </div>
            <div class="card">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Member</th>
                            <th>Role</th>
                            <th>KYC Status</th>
                            <th>Date Joined</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.users.map(u => `
                            <tr>
                                <td>
                                    <div class="user-cell">
                                        <div class="user-avatar">${u.full_name[0]}</div>
                                        <div class="details">
                                            <span style="color: var(--text-bright); font-weight: 600;">${u.full_name}</span>
                                            <small>${u.email || u.phone}</small>
                                        </div>
                                    </div>
                                </td>
                                <td><span class="role-badge ${u.role}">${u.role}</span></td>
                                <td>${ui.badge(u.kyc_status, u.kyc_status)}</td>
                                <td>${new Date(u.created_at).toLocaleDateString()}</td>
                                <td><button class="icon-btn"><i data-lucide="more-horizontal"></i></button></td>
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
        content.innerHTML = ui.loader();
        const data = await api.get(`/admin/orders${state.searchQuery ? '?search='+state.searchQuery : ''}`);
        
        content.innerHTML = `
            <h1 class="page-title" style="margin-bottom: 32px">Order Logistics</h1>
            <div class="card">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Number</th>
                            <th>Customer</th>
                            <th>Rider</th>
                            <th>Fare</th>
                            <th>Status</th>
                            <th>Timeline</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.orders.map(o => `
                            <tr>
                                <td style="color: var(--accent-blue);">#${o.order_number}</td>
                                <td>${o.customer_name}</td>
                                <td>${o.rider_name || '<em style="color: var(--text-secondary)">Unassigned</em>'}</td>
                                <td>${ui.currency(o.total_fare)}</td>
                                <td>${ui.badge(o.status, o.status)}</td>
                                <td>${new Date(o.created_at).toLocaleString([], {month:'short', day:'numeric', hour:'2-digit', minute:'2-digit'})}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
        lucide.createIcons();
    },

    'vendors': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = ui.loader();
        const data = await api.get(`/admin/users?role=vendor${state.searchQuery ? '&search='+state.searchQuery : ''}`);
        
        content.innerHTML = `
            <h1 class="page-title" style="margin-bottom: 32px">Vendor Partners</h1>
            <div class="card">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>Store</th>
                            <th>Categories</th>
                            <th>Onboarded</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.users.map(v => `
                            <tr>
                                <td>
                                    <div class="user-cell">
                                        <div class="user-avatar" style="background: var(--accent-purple)">${v.full_name[0]}</div>
                                        <div class="details">
                                            <span style="color: var(--text-bright); font-weight: 600;">${v.full_name}</span>
                                            <small>${v.email}</small>
                                        </div>
                                    </div>
                                </td>
                                <td>Groceries, Essentials</td>
                                <td>${new Date(v.created_at).toLocaleDateString()}</td>
                                <td><span class="kyc-badge verified">Active</span></td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
        lucide.createIcons();
    },

    'kyc': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = ui.loader();
        const data = await api.get('/admin/users?kyc_status=pending');

        content.innerHTML = `
            <h1 class="page-title" style="margin-bottom: 32px">Identity Verification</h1>
            <div class="card">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>User</th>
                            <th>Type</th>
                            <th>Submitted</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${data.users.map(u => `
                            <tr>
                                <td>${u.full_name} <br> <small>${u.email}</small></td>
                                <td>Goverment ID Card</td>
                                <td>${new Date(u.created_at).toLocaleDateString()}</td>
                                <td>
                                    <button class="btn-primary small" onclick="verifyUser('${u.id}', 'verified')">Approve</button>
                                    <button class="btn-primary small secondary" onclick="verifyUser('${u.id}', 'rejected')">Reject</button>
                                </td>
                            </tr>
                        `).join('')}
                        ${data.users.length === 0 ? '<tr><td colspan="4" style="text-align:center; padding: 64px; color: var(--text-secondary)">No documents pending review.</td></tr>' : ''}
                    </tbody>
                </table>
            </div>
        `;
        lucide.createIcons();
        window.verifyUser = async (id, status) => {
            const res = await api.put(`/admin/users/${id}/kyc`, { status });
            if (res.success) routes.kyc();
        };
    },

    'settings': async () => {
        const content = document.getElementById('page-content');
        content.innerHTML = ui.loader();
        const data = await api.get('/admin/settings');
        const s = data.settings;

        content.innerHTML = `
            <h1 class="page-title" style="margin-bottom: 32px">Global Control Center</h1>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 32px;">
                <div class="card p-24">
                    <h2 style="margin-bottom: 24px; color: var(--accent-green);">System Parameters</h2>
                    <div class="setting-item">
                        <div class="info"><h3>Service Commission</h3><p>Percentage cut from every order</p></div>
                        <div class="action"><input type="number" id="set-fee" value="${s.service_fee}"> %</div>
                    </div>
                    <div class="setting-item">
                        <div class="info"><h3>Base Delivery Fare</h3><p>Starting fare for all orders</p></div>
                        <div class="action">₦ <input type="number" id="set-base" value="${s.base_fare}"></div>
                    </div>
                    <div class="setting-item">
                        <div class="info"><h3>Min Withdrawal</h3><p>Minimum payout balance</p></div>
                        <div class="action">₦ <input type="number" id="set-min" value="${s.min_withdrawal}"></div>
                    </div>
                    <div class="card-footer">
                        <button class="btn-primary" onclick="updateSettings()">Apply Changes</button>
                    </div>
                </div>

                <div class="card p-24">
                    <h2 style="margin-bottom: 24px; color: var(--accent-blue);">Direct Broadcast</h2>
                    <div class="form-group">
                        <label>Audience Segment</label>
                        <select id="notif-target" class="form-select" style="background: var(--glass-bg); color: var(--text-bright); border: 1px solid var(--border-subtle); padding: 10px; border-radius: 8px;">
                            <option value="all">Everywhere (All Users)</option>
                            <option value="riders">Logistics Only (Riders)</option>
                            <option value="vendors">Store Fronts (Vendors)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Announcement Title</label>
                        <input type="text" id="notif-title" placeholder="e.g. System Maintenance">
                    </div>
                    <div class="form-group">
                        <label>Message Payload</label>
                        <textarea id="notif-msg" rows="4" placeholder="Enter notification content..."></textarea>
                    </div>
                    <button class="btn-primary" style="background: var(--accent-blue)" onclick="sendBroadcast()">Launch Notification</button>
                </div>
            </div>
        `;
        lucide.createIcons();

        window.updateSettings = async () => {
            const body = {
                service_fee: document.getElementById('set-fee').value,
                base_fare: document.getElementById('set-base').value,
                min_withdrawal: document.getElementById('set-min').value
            };
            const res = await api.put('/admin/settings', body);
            if (res.success) alert('System configuration updated!');
        };

        window.sendBroadcast = async () => {
            const body = {
                target: document.getElementById('notif-target').value,
                title: document.getElementById('notif-title').value,
                message: document.getElementById('notif-msg').value
            };
            const res = await api.post('/admin/notifications/broadcast', body);
            if (res.success) alert('Broadcast sent to all devices!');
        };
    }
};

// ============================================
// CORE NAVIGATION & INIT
// ============================================

async function navigate() {
    const hash = window.location.hash.replace('#/', '') || 'dashboard';
    state.currentPage = hash;

    document.querySelectorAll('.nav-item').forEach(el => {
        el.classList.toggle('active', el.getAttribute('href') === `#/${hash}`);
    });

    if (routes[hash]) await routes[hash]();
}

// Global Search
document.querySelector('.header-search input').addEventListener('input', (e) => {
    state.searchQuery = e.target.value;
    if (['users', 'orders'].includes(state.currentPage)) {
        clearTimeout(window.searchTimeout);
        window.searchTimeout = setTimeout(navigate, 400); 
    }
});

// Auth Persistence
async function init() {
    if (!state.token) {
        document.getElementById('login-overlay').classList.remove('hidden');
    } else {
        document.getElementById('login-overlay').classList.add('hidden');
        navigate();
    }
}

document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;
    const errorEl = document.getElementById('login-error');

    const res = await api.post('/auth/login', { email, password });
    if (res?.success && res.data.user.role === 'admin') {
        state.token = res.data.tokens.accessToken;
        state.user = res.data.user;
        localStorage.setItem('zippa_admin_token', state.token);
        
        document.getElementById('admin-name').textContent = state.user.fullName;
        document.getElementById('admin-avatar-char').textContent = state.user.fullName[0];
        document.getElementById('login-overlay').classList.add('hidden');
        navigate();
    } else {
        errorEl.textContent = res?.message || 'Unauthorized Access';
        errorEl.classList.remove('hidden');
    }
});

document.getElementById('logout-btn').addEventListener('click', () => api.logout());

window.addEventListener('hashchange', navigate);
window.addEventListener('load', init);
lucide.createIcons();
