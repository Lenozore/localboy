// ─── CONFIG ──────────────────────────────────────────
const API_BASE = 'http://localhost:3000/api';

// ─── STATE ───────────────────────────────────────────
let adminToken = localStorage.getItem('admin_token');
let adminInfo = JSON.parse(localStorage.getItem('admin_info') || 'null');
let devToken = sessionStorage.getItem('dev_token');
let isSignupMode = true;
let currentSection = 'dashboard';
let allUsers = [];

// ─── INIT ────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    setupNavigation();
    checkAuth();
});

function setupNavigation() {
    document.querySelectorAll('.nav-item:not(.dev-nav)').forEach(item => {
        item.addEventListener('click', () => {
            const section = item.dataset.section;
            switchSection(section);
        });
    });
}

function switchSection(section) {
    currentSection = section;
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    const navItem = document.querySelector(`.nav-item[data-section="${section}"]`);
    if (navItem) navItem.classList.add('active');

    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    document.getElementById(`section-${section}`).classList.add('active');
    document.getElementById('pageTitle').textContent = navItem?.textContent.trim() || section;

    loadSectionData(section);
}

function loadSectionData(section) {
    switch (section) {
        case 'dashboard': loadDashboard(); break;
        case 'users': loadUsers(); break;
        case 'trips': loadTrips(); break;
        case 'payments': loadPayments(); break;
        case 'documents': loadDocuments(); break;
        case 'complaints': loadComplaints(); break;
    }
}

function refreshCurrentSection() {
    loadSectionData(currentSection);
}

// ─── API HELPER ──────────────────────────────────────
async function api(endpoint, options = {}) {
    try {
        const res = await fetch(`${API_BASE}${endpoint}`, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...(adminToken ? { 'Authorization': `Bearer ${adminToken}` } : {}),
                ...options.headers,
            },
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.message || 'Request failed');
        return data;
    } catch (e) {
        console.warn(`API: ${endpoint}`, e.message);
        throw e;
    }
}

// ─── ADMIN AUTH ──────────────────────────────────────

function checkAuth() {
    if (adminToken && adminInfo) {
        showDashboard();
    } else {
        showAuthOverlay();
    }
}

function showAuthOverlay() {
    document.getElementById('authOverlay').classList.remove('hidden');
    document.getElementById('mainContent').style.display = 'none';
    document.getElementById('sidebar').style.display = 'none';
}

function showDashboard() {
    document.getElementById('authOverlay').classList.add('hidden');
    document.getElementById('mainContent').style.display = '';
    document.getElementById('sidebar').style.display = '';
    document.getElementById('adminAvatar').textContent = (adminInfo?.name || 'A')[0].toUpperCase();
    document.getElementById('adminNameDisplay').textContent = adminInfo?.name || 'Admin';
    loadDashboard();
}

function toggleAuthMode() {
    isSignupMode = !isSignupMode;
    document.getElementById('signupFields').style.display = isSignupMode ? '' : 'none';
    document.getElementById('authSubtitle').textContent = isSignupMode
        ? 'Create your admin account'
        : 'Login to your admin account';
    document.getElementById('authBtn').textContent = isSignupMode ? 'Create Account' : 'Login';
    document.getElementById('authToggle').innerHTML = isSignupMode
        ? 'Already have an account? <a href="#" onclick="toggleAuthMode()">Login</a>'
        : 'Need an account? <a href="#" onclick="toggleAuthMode()">Sign Up</a>';
    document.getElementById('authError').textContent = '';
}

async function handleAuth() {
    const email = document.getElementById('adminEmail').value.trim();
    const password = document.getElementById('adminPassword').value;
    const errorEl = document.getElementById('authError');

    if (!email || !password) {
        errorEl.textContent = 'Please fill all fields';
        return;
    }

    if (password.length < 6) {
        errorEl.textContent = 'Password must be at least 6 characters';
        return;
    }

    try {
        if (isSignupMode) {
            const name = document.getElementById('adminName').value.trim();
            if (!name) {
                errorEl.textContent = 'Please enter your name';
                return;
            }
            const data = await api('/admin/signup', {
                method: 'POST',
                body: JSON.stringify({ email, password, name }),
            });
            adminToken = data.token;
            adminInfo = data.admin;
        } else {
            const data = await api('/admin/login', {
                method: 'POST',
                body: JSON.stringify({ email, password }),
            });
            adminToken = data.token;
            adminInfo = data.admin;
        }

        localStorage.setItem('admin_token', adminToken);
        localStorage.setItem('admin_info', JSON.stringify(adminInfo));
        showDashboard();
    } catch (e) {
        errorEl.textContent = e.message || 'Authentication failed';
    }
}

function logout() {
    // Clear admin session
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_info');
    adminToken = null;
    adminInfo = null;

    // Also clear developer session completely
    sessionStorage.removeItem('dev_token');
    devToken = null;

    // Clear all form fields so no credentials persist
    document.getElementById('adminEmail').value = '';
    document.getElementById('adminPassword').value = '';
    document.getElementById('adminName').value = '';
    document.getElementById('devEmail').value = '';
    document.getElementById('devPassword').value = '';
    document.getElementById('devError').textContent = '';
    document.getElementById('authError').textContent = '';

    // Reset developer section to locked
    document.getElementById('devLocked').style.display = '';
    document.getElementById('devContent').classList.add('hidden');
    document.getElementById('devOverlay').classList.add('hidden');

    showAuthOverlay();
}

// ─── DEVELOPER AUTH ──────────────────────────────────

function openDevLogin() {
    if (devToken) {
        // Already authenticated
        switchSection('developer');
        document.getElementById('devLocked').style.display = 'none';
        document.getElementById('devContent').classList.remove('hidden');
        loadDevStats();
        return;
    }

    // Show on developer section but show locked state
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    document.querySelector('.dev-nav').classList.add('active');
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    document.getElementById('section-developer').classList.add('active');
    document.getElementById('pageTitle').textContent = '🔒 Developer';

    // Always clear form fields before showing
    document.getElementById('devEmail').value = '';
    document.getElementById('devPassword').value = '';
    document.getElementById('devError').textContent = '';
    document.getElementById('devOverlay').classList.remove('hidden');
}

async function devLogin() {
    const email = document.getElementById('devEmail').value.trim();
    const password = document.getElementById('devPassword').value;
    const errorEl = document.getElementById('devError');

    if (!email || !password) {
        errorEl.textContent = 'Please fill all fields';
        return;
    }

    try {
        const data = await api('/admin/developer/login', {
            method: 'POST',
            body: JSON.stringify({ email, password }),
        });

        devToken = data.token;
        sessionStorage.setItem('dev_token', devToken);

        document.getElementById('devOverlay').classList.add('hidden');
        document.getElementById('devLocked').style.display = 'none';
        document.getElementById('devContent').classList.remove('hidden');

        // Clear form fields after successful login
        document.getElementById('devEmail').value = '';
        document.getElementById('devPassword').value = '';
        document.getElementById('devError').textContent = '';

        loadDevStats();
    } catch (e) {
        errorEl.textContent = e.message || 'Invalid developer credentials';
    }
}

function closeDevLogin() {
    document.getElementById('devOverlay').classList.add('hidden');
    document.getElementById('devEmail').value = '';
    document.getElementById('devPassword').value = '';
    document.getElementById('devError').textContent = '';
    switchSection('dashboard');
}

function devLogout() {
    sessionStorage.removeItem('dev_token');
    devToken = null;

    // Clear form fields
    document.getElementById('devEmail').value = '';
    document.getElementById('devPassword').value = '';
    document.getElementById('devError').textContent = '';

    document.getElementById('devLocked').style.display = '';
    document.getElementById('devContent').classList.add('hidden');
    switchSection('dashboard');
}

// ─── DASHBOARD (REAL-TIME) ───────────────────────────

async function loadDashboard() {
    try {
        const stats = await api('/admin/stats');
        document.getElementById('totalUsers').textContent = stats.totalUsers || 0;
        document.getElementById('totalTrips').textContent = stats.totalTrips || 0;
        document.getElementById('totalRevenue').textContent = `₹${Math.round(stats.totalRevenue || 0).toLocaleString('en-IN')}`;
        document.getElementById('pendingDocs').textContent = stats.pendingDocs || 0;
        document.getElementById('touristCount').textContent = stats.tourists || 0;
        document.getElementById('driverCount').textContent = stats.drivers || 0;
        document.getElementById('guideCount').textContent = stats.guides || 0;
    } catch (e) {
        document.getElementById('totalUsers').textContent = '0';
        document.getElementById('totalTrips').textContent = '0';
        document.getElementById('totalRevenue').textContent = '₹0';
        document.getElementById('pendingDocs').textContent = '0';
        document.getElementById('touristCount').textContent = '0';
        document.getElementById('driverCount').textContent = '0';
        document.getElementById('guideCount').textContent = '0';
    }

    try {
        const activities = await api('/admin/recent-activity');
        const container = document.getElementById('recentActivity');

        if (!activities || activities.length === 0) {
            container.innerHTML = '<div class="empty-state"><div class="icon">📭</div><p>No activity yet. Data will appear as users interact with the platform.</p></div>';
            return;
        }

        container.innerHTML = activities.map(a => {
            const typeColors = { user: 'badge-info', trip: 'badge-success', payment: 'badge-warning' };
            return `<div class="activity-item">
                <span><span class="badge ${typeColors[a.type] || 'badge-info'} activity-type">${a.type}</span> ${a.text}</span>
                <span class="text-muted">${a.time}</span>
            </div>`;
        }).join('');
    } catch (e) {
        document.getElementById('recentActivity').innerHTML =
            '<div class="empty-state"><div class="icon">📭</div><p>No activity yet. Start the backend to see real-time data.</p></div>';
    }
}

// ─── USERS (REAL-TIME) ──────────────────────────────

async function loadUsers() {
    const role = document.getElementById('userRoleFilter').value;

    try {
        allUsers = await api(`/admin/users?role=${role}`);

        if (!allUsers || allUsers.length === 0) {
            document.getElementById('usersTable').innerHTML = '<tr><td colspan="6"><div class="empty-state"><div class="icon">👥</div><p>No users found</p></div></td></tr>';
            return;
        }

        renderUsers(allUsers);
    } catch (e) {
        document.getElementById('usersTable').innerHTML =
            '<tr><td colspan="6" class="text-muted">Could not load users. Make sure backend is running.</td></tr>';
    }
}

function renderUsers(users) {
    const roleColors = { tourist: 'info', driver: 'success', guide: 'warning', admin: 'danger' };
    document.getElementById('usersTable').innerHTML = users.map(u => `
        <tr>
            <td><strong>${u.name || '—'}</strong></td>
            <td>${u.phone || '—'}</td>
            <td>${u.email || '—'}</td>
            <td><span class="badge badge-${roleColors[u.role] || 'info'}">${u.role}</span></td>
            <td>${u.phone_verified ? '✅' : '❌'}</td>
            <td>${u.created_at ? new Date(u.created_at).toLocaleDateString() : '—'}</td>
        </tr>
    `).join('');
}

function filterUsersLocal() {
    const search = document.getElementById('userSearch').value.toLowerCase();
    if (!search) return renderUsers(allUsers);
    const filtered = allUsers.filter(u =>
        (u.name || '').toLowerCase().includes(search) ||
        (u.phone || '').includes(search) ||
        (u.email || '').toLowerCase().includes(search)
    );
    renderUsers(filtered);
}

// ─── TRIPS (REAL-TIME) ──────────────────────────────

async function loadTrips() {
    const status = document.getElementById('tripStatusFilter').value;

    try {
        const trips = await api(`/admin/trips?status=${status}`);

        if (!trips || trips.length === 0) {
            document.getElementById('tripsTable').innerHTML = '<tr><td colspan="7"><div class="empty-state"><div class="icon">🚗</div><p>No trips found</p></div></td></tr>';
            return;
        }

        const statusColors = { pending: 'warning', confirmed: 'info', driver_assigned: 'info', active: 'success', completed: 'success', cancelled: 'danger' };
        document.getElementById('tripsTable').innerHTML = trips.map(t => `
            <tr>
                <td><strong>${t.booking_code || '—'}</strong></td>
                <td>${t.tourist?.name || t.tourist_id?.substring(0, 8) || '—'}</td>
                <td>${t.driver?.name || t.driver_id?.substring(0, 8) || '—'}</td>
                <td>${t.trip_date || '—'}</td>
                <td>${(t.trip_type || '').replace('_', ' ')}</td>
                <td>₹${t.tourist_charge || 0}</td>
                <td><span class="badge badge-${statusColors[t.status] || 'info'}">${(t.status || '').replace('_', ' ')}</span></td>
            </tr>
        `).join('');
    } catch (e) {
        document.getElementById('tripsTable').innerHTML =
            '<tr><td colspan="7" class="text-muted">Could not load trips</td></tr>';
    }
}

// ─── PAYMENTS (REAL-TIME) ────────────────────────────

async function loadPayments() {
    try {
        const stats = await api('/admin/payment-stats');
        document.getElementById('paymentsReceived').textContent = `₹${Math.round(stats.collected || 0).toLocaleString('en-IN')}`;
        document.getElementById('payoutsPaid').textContent = `₹${Math.round(stats.payouts || 0).toLocaleString('en-IN')}`;
        document.getElementById('platformProfit').textContent = `₹${Math.round(stats.platformRevenue || 0).toLocaleString('en-IN')}`;
    } catch (e) {
        document.getElementById('paymentsReceived').textContent = '₹0';
        document.getElementById('payoutsPaid').textContent = '₹0';
        document.getElementById('platformProfit').textContent = '₹0';
    }

    try {
        const payments = await api('/admin/payments');

        if (!payments || payments.length === 0) {
            document.getElementById('paymentsTable').innerHTML = '<tr><td colspan="5"><div class="empty-state"><div class="icon">💳</div><p>No payments yet</p></div></td></tr>';
            return;
        }

        const statusColors = { completed: 'success', pending: 'warning', failed: 'danger' };
        document.getElementById('paymentsTable').innerHTML = payments.map(p => `
            <tr>
                <td><strong>${p.trip_id?.substring(0, 8) || '—'}</strong></td>
                <td>${(p.payment_type || '').replace(/_/g, ' ')}</td>
                <td>₹${p.amount || 0}</td>
                <td><span class="badge badge-${statusColors[p.status] || 'info'}">${p.status}</span></td>
                <td>${p.created_at ? new Date(p.created_at).toLocaleDateString() : '—'}</td>
            </tr>
        `).join('');
    } catch (e) {
        document.getElementById('paymentsTable').innerHTML =
            '<tr><td colspan="5" class="text-muted">Could not load payments</td></tr>';
    }
}

// ─── DOCUMENTS (REAL-TIME) ───────────────────────────

async function loadDocuments() {
    try {
        const docs = await api('/admin/documents');

        const pending = docs ? docs.filter(d => d.status === 'pending').length : 0;
        document.getElementById('pendingDocsBadge').textContent = `${pending} pending`;

        if (!docs || docs.length === 0) {
            document.getElementById('documentsTable').innerHTML = '<tr><td colspan="5"><div class="empty-state"><div class="icon">📄</div><p>No documents uploaded yet</p></div></td></tr>';
            return;
        }

        document.getElementById('documentsTable').innerHTML = docs.map(d => `
            <tr>
                <td><strong>${d.user?.name || d.user_id?.substring(0, 8) || '—'}</strong></td>
                <td>${(d.doc_type || '').replace(/_/g, ' ')}</td>
                <td><span class="text-muted">${d.file_name || '—'}</span></td>
                <td><span class="badge badge-${d.status === 'approved' ? 'success' : d.status === 'rejected' ? 'danger' : 'warning'}">${d.status}</span></td>
                <td>${d.status === 'pending' ?
                `<button class="btn btn-sm btn-success" onclick="reviewDoc('${d.id}', 'approved')">Approve</button>
                     <button class="btn btn-sm btn-danger" onclick="reviewDoc('${d.id}', 'rejected')">Reject</button>` : '—'}</td>
            </tr>
        `).join('');
    } catch (e) {
        document.getElementById('documentsTable').innerHTML =
            '<tr><td colspan="5" class="text-muted">Could not load documents</td></tr>';
    }
}

async function reviewDoc(docId, status) {
    try {
        await api(`/admin/documents/${docId}/review`, {
            method: 'POST',
            body: JSON.stringify({ status }),
        });
        loadDocuments();
    } catch (e) {
        alert('Failed to review document: ' + e.message);
    }
}

// ─── COMPLAINTS (REAL-TIME) ──────────────────────────

async function loadComplaints() {
    try {
        const complaints = await api('/admin/complaints');

        if (!complaints || complaints.length === 0) {
            document.getElementById('complaintsList').innerHTML =
                '<div class="empty-state"><div class="icon">✅</div><p>No complaints — everything is running smoothly!</p></div>';
            return;
        }

        document.getElementById('complaintsList').innerHTML = complaints.map(c => `
            <div class="activity-item">
                <span><strong>${c.user?.name || 'User'}</strong>: ${c.content || c.description || '—'}</span>
                <span class="badge badge-${c.status === 'resolved' ? 'success' : 'warning'}">${c.status || 'open'}</span>
            </div>
        `).join('');
    } catch (e) {
        document.getElementById('complaintsList').innerHTML =
            '<div class="empty-state"><div class="icon">✅</div><p>No complaints yet</p></div>';
    }
}

// ─── DEVELOPER STATS (REAL-TIME) ─────────────────────

async function loadDevStats() {
    try {
        const stats = await api('/admin/developer/stats');
        document.getElementById('dbUsers').textContent = stats.userCount || 0;
        document.getElementById('dbTrips').textContent = stats.tripCount || 0;
        document.getElementById('dbPayments').textContent = stats.paymentCount || 0;
        document.getElementById('dbDocuments').textContent = stats.documentCount || 0;
        document.getElementById('dbComplaints').textContent = stats.complaintCount || 0;
        document.getElementById('dbPois').textContent = stats.poiCount || 0;
    } catch (e) {
        console.warn('Could not load dev stats', e);
    }
}
