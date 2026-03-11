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
    'users': () => {
        document.getElementById('page-content').innerHTML = '<h1 class="page-title">User Management</h1><p>Feature coming soon...</p>';
    },
    'orders': () => {
        document.getElementById('page-content').innerHTML = '<h1 class="page-title">Order Management</h1><p>Feature coming soon...</p>';
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
