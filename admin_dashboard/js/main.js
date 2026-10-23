/**
 * NexRide Admin Dashboard - Main JS
 * Handles Login Auth, Routing, and Theme selection.
 * Falls back to rich BMTC example data when backend is offline.
 */

const BASE_URL = 'http://127.0.0.1:8000';
let jwtToken = localStorage.getItem('nexride_admin_token');

// ── BMTC Mock Data ────────────────────────────────────────────────────────────
const MOCK = {
  stats: { buses: 148, routes: 42, users: 5831, total_tickets: 2947 },

  buses: [
    { id:1, bus_number:'KA-01-F-4011', route_id:'500A', latitude:12.9716, longitude:77.5946, speed_kmh:34.2, status:'On Route', capacity:60, current_occupancy:52 },
    { id:2, bus_number:'KA-57-F-1100', route_id:'335E', latitude:12.9784, longitude:77.6408, speed_kmh:18.7, status:'On Route', capacity:60, current_occupancy:24 },
    { id:3, bus_number:'KA-53-F-2211', route_id:'201',  latitude:12.9352, longitude:77.6245, speed_kmh:41.0, status:'On Route', capacity:60, current_occupancy:58 },
    { id:4, bus_number:'KA-04-F-3910', route_id:'600C', latitude:13.0012, longitude:77.5800, speed_kmh:0,    status:'At Stop',  capacity:60, current_occupancy:12 },
    { id:5, bus_number:'KA-51-A-4122', route_id:'401G', latitude:12.9650, longitude:77.6101, speed_kmh:27.5, status:'On Route', capacity:60, current_occupancy:45 },
    { id:6, bus_number:'KA-01-F-9021', route_id:'273K', latitude:12.9900, longitude:77.5750, speed_kmh:55.1, status:'On Route', capacity:60, current_occupancy:36 },
    { id:7, bus_number:'KA-57-F-3345', route_id:'500A', latitude:12.9550, longitude:77.6300, speed_kmh:0,    status:'Depot',    capacity:60, current_occupancy:0  },
  ],

  routes: [
    { id:'500A', route_number:'500A', origin:'Kempegowda Bus Stand', destination:'Electronic City', estimated_duration_min:75, fare_amount:42, is_active:true,  driver:'Ramesh K.',     conductor:'Suresh P.',  vehicle:'KA-01-F-4011', crowd:88 },
    { id:'335E', route_number:'335E', origin:'Majestic',             destination:'Whitefield',       estimated_duration_min:90, fare_amount:55, is_active:true,  driver:'Manjunath S.',  conductor:'Naveen T.',  vehicle:'KA-57-F-1100', crowd:40 },
    { id:'201',  route_number:'201',  origin:'Shivajinagar',         destination:'Banashankari',     estimated_duration_min:55, fare_amount:28, is_active:true,  driver:'Venkatesh S.',  conductor:'Raju B.',    vehicle:'KA-53-F-2211', crowd:97 },
    { id:'600C', route_number:'600C', origin:'Yeshwanthpur',         destination:'KR Puram',         estimated_duration_min:65, fare_amount:35, is_active:true,  driver:'Prakash G.',    conductor:'Satish M.',  vehicle:'KA-04-F-3910', crowd:22 },
    { id:'401G', route_number:'401G', origin:'Hebbal',               destination:'JP Nagar',         estimated_duration_min:80, fare_amount:48, is_active:true,  driver:'Shivakumar R.', conductor:'Kumar B.',   vehicle:'KA-51-A-4122', crowd:76 },
    { id:'273K', route_number:'273K', origin:'Rajajinagar',          destination:'Koramangala',      estimated_duration_min:50, fare_amount:30, is_active:true,  driver:'Narayan D.',    conductor:'Srinivas V.',vehicle:'KA-01-F-9021', crowd:60 },
    { id:'118B', route_number:'118B', origin:'Yelahanka',            destination:'Silk Board',       estimated_duration_min:95, fare_amount:60, is_active:false, driver:'Govind P.',     conductor:'Mahesh T.',  vehicle:'KA-57-F-3345', crowd:0  },
  ],

  users: [
    { id:'usr-a1b2c3', name:'Aarav Sharma',    email:'aarav.sharma@gmail.com',   phone:'+91 98450 11223', wallet_balance:248.50, is_active:true,  is_verified:true,  created_at:'2024-11-12' },
    { id:'usr-d4e5f6', name:'Priya Nair',       email:'priya.nair@outlook.com',   phone:'+91 97312 44556', wallet_balance:82.00,  is_active:true,  is_verified:true,  created_at:'2025-01-05' },
    { id:'usr-g7h8i9', name:'Rohit Desai',      email:'rohit.desai@yahoo.com',    phone:'+91 80456 78901', wallet_balance:5.75,   is_active:true,  is_verified:false, created_at:'2025-03-19' },
    { id:'usr-j1k2l3', name:'Sneha Kulkarni',   email:'sneha.k@nexride.in',       phone:'+91 99003 22114', wallet_balance:540.00, is_active:true,  is_verified:true,  created_at:'2024-09-28' },
    { id:'usr-m4n5o6', name:'Vikram Reddy',     email:'vikram.r@gmail.com',       phone:'+91 70123 55678', wallet_balance:15.20,  is_active:false, is_verified:true,  created_at:'2024-07-14' },
    { id:'usr-p7q8r9', name:'Ananya Iyer',      email:'ananya.iyer@gmail.com',    phone:'+91 88991 00234', wallet_balance:320.00, is_active:true,  is_verified:true,  created_at:'2025-02-08' },
    { id:'usr-s1t2u3', name:'Karthik Menon',    email:'karthik.m@hotmail.com',    phone:'+91 76543 21098', wallet_balance:195.40, is_active:true,  is_verified:true,  created_at:'2025-04-01' },
    { id:'usr-v4w5x6', name:'Divya Krishnan',   email:'divya.k@gmail.com',        phone:'+91 91234 56789', wallet_balance:60.00,  is_active:true,  is_verified:false, created_at:'2025-05-03' },
  ],

  tickets: [
    { id:'TKT-9021', route_id:'500A', origin_stop:'Kempegowda BS',  destination_stop:'Silk Board',    fare:42, status:'active',  issued_at: new Date(Date.now()-8*60000).toISOString() },
    { id:'TKT-9022', route_id:'201',  origin_stop:'Shivajinagar',   destination_stop:'Jayanagar 4th', fare:18, status:'active',  issued_at: new Date(Date.now()-15*60000).toISOString() },
    { id:'TKT-9023', route_id:'335E', origin_stop:'Majestic',       destination_stop:'Marathahalli',  fare:35, status:'used',    issued_at: new Date(Date.now()-32*60000).toISOString() },
    { id:'TKT-9024', route_id:'401G', origin_stop:'Hebbal',         destination_stop:'Koramangala',   fare:48, status:'active',  issued_at: new Date(Date.now()-44*60000).toISOString() },
    { id:'TKT-9025', route_id:'600C', origin_stop:'Yeshwanthpur',   destination_stop:'KR Puram',      fare:35, status:'used',    issued_at: new Date(Date.now()-60*60000).toISOString() },
    { id:'TKT-9026', route_id:'273K', origin_stop:'Rajajinagar',    destination_stop:'Koramangala',   fare:30, status:'active',  issued_at: new Date(Date.now()-75*60000).toISOString() },
    { id:'TKT-9027', route_id:'500A', origin_stop:'Electronic City',destination_stop:'Silk Board',    fare:25, status:'used',    issued_at: new Date(Date.now()-92*60000).toISOString() },
    { id:'TKT-9028', route_id:'201',  origin_stop:'Banashankari',   destination_stop:'BTM Layout',    fare:12, status:'active',  issued_at: new Date(Date.now()-110*60000).toISOString() },
    { id:'TKT-9029', route_id:'335E', origin_stop:'Whitefield',     destination_stop:'Majestic',      fare:55, status:'active',  issued_at: new Date(Date.now()-125*60000).toISOString() },
    { id:'TKT-9030', route_id:'401G', origin_stop:'JP Nagar',       destination_stop:'MG Road',       fare:28, status:'expired', issued_at: new Date(Date.now()-180*60000).toISOString() },
  ],
};

// ── DOM loaded handler
document.addEventListener('DOMContentLoaded', () => {

    // Auto-login check
    if (window.location.pathname.endsWith('index.html') || window.location.pathname === '/') {
        if (jwtToken) {
            window.location.href = 'dashboard.html';
        } else {
            setupLogin();
        }
    }
    else if (window.location.pathname.endsWith('dashboard.html')) {
        if (!jwtToken) {
            window.location.href = 'index.html';
        } else {
            setupDashboard();
        }
    }

    // Theme toggle initialization
    initTheme();
});

// ── 1. Login Handling ────────────────────────────────────────────────────────
function setupLogin() {
    const form = document.getElementById('loginForm');
    const btn = document.getElementById('loginBtn');
    const err = document.getElementById('loginError');

    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;

        btn.innerHTML = '<i class="fa-solid fa-circle-notch fa-spin"></i>';
        btn.disabled = true;
        err.innerText = '';

        try {
            const res = await fetch(`${BASE_URL}/auth/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: email, password: password })
            });

            const data = await res.json();

            if (!res.ok) {
                let errorMsg = 'Login failed';
                if (typeof data.detail === 'string') errorMsg = data.detail;
                else if (Array.isArray(data.detail)) errorMsg = data.detail[0].msg;
                else if (typeof data.detail === 'object') errorMsg = JSON.stringify(data.detail);

                throw new Error(errorMsg);
            }

            localStorage.setItem('nexride_admin_token', data.access_token);
            window.location.href = 'dashboard.html';

        } catch (error) {
            err.innerText = error.message;
            btn.innerHTML = '<span>Access Dashboard</span> <i class="fa-solid fa-arrow-right"></i>';
            btn.disabled = false;
        }
    });
}

// ── 2. Dashboard Logic ───────────────────────────────────────────────────────
function setupDashboard() {
    // Nav handling
    const navLinks = document.querySelectorAll('.nav-links a');
    const panels = document.querySelectorAll('.panel');
    const pageTitle = document.getElementById('pageTitle');

    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();

            // Remove active class
            navLinks.forEach(l => l.classList.remove('active'));
            panels.forEach(p => p.classList.remove('active'));

            // Add active class
            link.classList.add('active');
            const targetId = link.getAttribute('data-target');
            document.getElementById(`panel-${targetId}`).classList.add('active');

            // Update title
            pageTitle.innerText = link.innerText.trim();

            // Leaflet requires invalidateSize when unhidden
            if (targetId === 'tracking') {
                setTimeout(() => {
                    if (window.mapObj) window.mapObj.invalidateSize();
                }, 200);
            }
        });
    });

    // Logout
    document.getElementById('logoutBtn').addEventListener('click', (e) => {
        e.preventDefault();
        localStorage.removeItem('nexride_admin_token');
        window.location.href = 'index.html';
    });

    document.getElementById('adminName').innerText = 'Admin System';

    // Floating example-data badge
    const badge = document.createElement('div');
    badge.id = 'exampleDataBadge';
    badge.innerHTML = '<i class="fa-solid fa-flask"></i> Example Data Mode';
    badge.style.cssText = 'position:fixed;bottom:20px;right:20px;z-index:9999;background:rgba(245,158,11,0.18);color:#f59e0b;border:1px solid rgba(245,158,11,0.35);padding:7px 14px;border-radius:20px;font-size:12px;font-weight:600;backdrop-filter:blur(8px);pointer-events:none;letter-spacing:0.3px;';
    document.body.appendChild(badge);

    // Step 2: Auto-refresh stats every 5 seconds
    loadDashboardStats();
    setInterval(loadDashboardStats, 5000);

    // Step 3 map logic
    initTrackingMap();
    fetchBuses();
    setInterval(fetchBuses, 5000); // Poll every 5s

    // Step 4 routes logic
    fetchRoutes();

    // Step 5 users logic
    fetchUsers();

    // Step 6 tickets logic
    fetchTickets();
    setInterval(fetchTickets, 5000);
}

// ── 2a. Fetch Overview Stats ──────────────────────────────────────────────────
async function loadDashboardStats() {
    try {
        const res = await fetch(`${BASE_URL}/admin/stats`, {
            headers: { 'Authorization': `Bearer ${jwtToken}` }
        });
        if (!res.ok) throw new Error('stats fetch failed');
        const data = await res.json();
        animateValue('statBuses',   data.buses);
        animateValue('statRoutes',  data.routes);
        animateValue('statUsers',   data.users);
        animateValue('statTickets', data.total_tickets);
    } catch (e) {
        // Fallback to BMTC mock stats
        animateValue('statBuses',   MOCK.stats.buses);
        animateValue('statRoutes',  MOCK.stats.routes);
        animateValue('statUsers',   MOCK.stats.users);
        animateValue('statTickets', MOCK.stats.total_tickets);
    }
}

function animateValue(id, endVal) {
    const obj = document.getElementById(id);
    if (!obj) return;

    const startVal = parseInt(obj.innerText) || 0;
    if (startVal === endVal) return; // Unchanged

    // Simple 500ms counter animation
    const duration = 500;
    const startObj = performance.now();

    const step = (now) => {
        const progress = Math.min((now - startObj) / duration, 1);
        obj.innerText = Math.floor(progress * (endVal - startVal) + startVal);
        if (progress < 1) {
            window.requestAnimationFrame(step);
        } else {
            obj.innerText = endVal;
        }
    };
    window.requestAnimationFrame(step);
}

// ── Step 3: Live Bus Tracking ────────────────────────────────────────────────
let markers = {};

function initTrackingMap() {
    // 12.9716, 77.5946 = Bangalore
    window.mapObj = L.map('busMap', { zoomControl: false }).setView([12.9716, 77.5946], 12);
    L.control.zoom({ position: 'bottomright' }).addTo(window.mapObj);

    // Google Maps Tile Layer
    L.tileLayer('http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}', {
        maxZoom: 20,
        attribution: '&copy; Google Maps'
    }).addTo(window.mapObj);
}

async function fetchBuses() {
    let buses;
    try {
        const res = await fetch(`${BASE_URL}/buses/`, {
            headers: { 'Authorization': `Bearer ${jwtToken}` }
        });
        if (!res.ok) throw new Error('buses fetch failed');
        buses = await res.json();
    } catch (e) {
        buses = MOCK.buses;
    }

        const listEl = document.getElementById('busFleetList');
        // Clear list
        listEl.innerHTML = '';

        buses.forEach(bus => {
            if (!bus.latitude || !bus.longitude) return;

            // 1. Plot on map
            if (markers[bus.id]) {
                // Update position smoothly
                markers[bus.id].setLatLng([bus.latitude, bus.longitude]);
                markers[bus.id].setPopupContent(`<div class="bus-info-sm">
                                <h5>${bus.bus_number}</h5>
                                <p><b>Route:</b> ${bus.route_id || 'N/A'}</p>
                                <p><b>Speed:</b> ${parseFloat(bus.speed_kmh).toFixed(1)} km/h</p>
                            </div>`);
            } else {
                // Create
                const customIcon = L.divIcon({
                    className: 'custom-bus-icon',
                    html: `<div class="bus-icon-sm"><i class="fa-solid fa-bus"></i></div>`,
                    iconSize: [30, 30],
                    iconAnchor: [15, 15]
                });

                // Changed map popups to include vehicle Route + Speed 
                const marker = L.marker([bus.latitude, bus.longitude], { icon: customIcon })
                    .bindPopup(`<div class="bus-info-sm">
                                    <h5>${bus.bus_number}</h5>
                                    <p><b>Route:</b> ${bus.route_id || 'N/A'}</p>
                                    <p><b>Speed:</b> ${parseFloat(bus.speed_kmh).toFixed(1)} km/h</p>
                                </div>`);
                marker.addTo(window.mapObj);
                markers[bus.id] = marker;
            }

            // 2. Add to list
            const occupancy = bus.capacity > 0 ? Math.round((bus.current_occupancy / bus.capacity) * 100) : 0;
            let crowdColor = occupancy < 40 ? 'var(--success)' : (occupancy < 75 ? 'var(--warning)' : 'var(--danger)');

            listEl.innerHTML += `
                <div class="bus-item" onclick="flyToBus(${bus.latitude}, ${bus.longitude})">
                    <div class="bus-icon-sm">
                        <i class="fa-solid fa-bus"></i>
                    </div>
                    <div class="bus-info-sm" style="flex-grow:1">
                        <h5>${bus.bus_number}</h5>
                        <p>Route: ${bus.route_id || 'N/A'} • Spd: ${bus.speed_kmh?.toFixed(0) || 0}km/h</p>
                    </div>
                    <div style="text-align:right">
                        <span style="font-size:12px; font-weight:600; color:${crowdColor}">${occupancy}% Full</span><br>
                        <span style="font-size:10px; color:var(--text-secondary)">${bus.status}</span>
                    </div>
                </div>
            `;
        });
}

function flyToBus(lat, lng) {
    if (window.mapObj && lat && lng) {
        window.mapObj.flyTo([lat, lng], 15, { duration: 1.5 });
    }
}

// ── Step 4: Route Management ────────────────────────────────────────────────
async function fetchRoutes() {
    let routes;
    try {
        const res = await fetch(`${BASE_URL}/routes/`, {
            headers: { 'Authorization': `Bearer ${jwtToken}` }
        });
        if (!res.ok) throw new Error('routes fetch failed');
        routes = await res.json();
    } catch (e) {
        routes = MOCK.routes;
    }

    const tbody = document.getElementById('routesTableBody');
    tbody.innerHTML = '';
    if (routes.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:30px;">No operating routes found.</td></tr>';
        return;
    }

    routes.forEach(route => {
        const driver    = route.driver    || 'N/A';
        const conductor = route.conductor || 'N/A';
        const vehicle   = route.vehicle   || 'N/A';
        const crowdPct  = route.crowd !== undefined ? route.crowd : Math.floor(Math.random()*65)+30;
        let crowdColor = crowdPct > 80 ? 'var(--danger)' : crowdPct > 55 ? 'var(--warning)' : 'var(--success)';
        const statusDot = route.is_active
            ? '<span class="status-badge status-active">Active</span>'
            : '<span class="status-badge status-inactive">Inactive</span>';

        tbody.innerHTML += `
            <tr>
                <td>
                    <span class="route-badge"><i class="fa-solid fa-route"></i> ${String(route.id).toUpperCase()}</span>
                    <div style="font-size:10px;color:var(--text-secondary);margin-top:4px;">${route.route_number || ''} ${statusDot}</div>
                </td>
                <td>
                    <div style="font-size:12px;margin-bottom:2px;"><i class="fa-solid fa-id-card"></i> <b>Driver:</b> ${driver}</div>
                    <div style="font-size:12px;margin-bottom:2px;color:var(--text-secondary)"><i class="fa-solid fa-ticket"></i> <b>Cond:</b> ${conductor}</div>
                    <div style="font-size:11px;background:rgba(255,255,255,0.05);padding:2px 6px;display:inline-block;border-radius:3px;">${vehicle}</div>
                </td>
                <td>
                    <strong style="font-size:13px;">${route.origin}</strong>
                    <div style="font-size:11px;color:var(--text-secondary);margin:2px 0;"><i class="fa-solid fa-arrow-down"></i> via BMTC Network</div>
                    <strong style="font-size:13px;">${route.destination}</strong>
                </td>
                <td><i class="fa-regular fa-clock text-secondary"></i> ${route.estimated_duration_min} min</td>
                <td>₹${route.fare_amount}</td>
                <td>
                    <div style="display:flex;align-items:center;gap:8px;">
                        <strong style="color:${crowdColor}">${crowdPct}%</strong>
                        <div style="width:50px;height:6px;background:rgba(255,255,255,0.1);border-radius:3px;overflow:hidden;">
                            <div style="width:${crowdPct}%;height:100%;background:${crowdColor};"></div>
                        </div>
                    </div>
                </td>
                <td>
                    <button class="action-btn"><i class="fa-solid fa-pen-to-square"></i></button>
                    <button class="action-btn delete"><i class="fa-solid fa-trash-can"></i></button>
                </td>
            </tr>
        `;
    });
}

// ── Step 5: User Management ──────────────────────────────────────────────────
async function fetchUsers() {
    let users;
    try {
        const res = await fetch(`${BASE_URL}/admin/users`, {
            headers: { 'Authorization': `Bearer ${jwtToken}` }
        });
        if (!res.ok) throw new Error('users fetch failed');
        users = await res.json();
    } catch (e) {
        users = MOCK.users;
    }

        const tbody = document.getElementById('usersTableBody');
        tbody.innerHTML = '';

        if (users.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:30px;">No users found.</td></tr>';
            return;
        }

        users.forEach(user => {
            const statusClass = user.is_active ? 'status-active' : 'status-inactive';
            const statusText = user.is_active ? 'Active' : 'Banned';
            const verifyIcon = user.is_verified ? '<i class="fa-solid fa-circle-check text-success"></i>' : '<i class="fa-solid fa-clock text-warning"></i>';
            const joinDate = new Date(user.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });

            // Generate Avatar
            const avatarUrl = `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=random&color=fff`;

            tbody.innerHTML += `
                <tr>
                    <td>
                        <div style="display:flex; align-items:center; gap:12px;">
                            <img src="${avatarUrl}" alt="${user.name}" style="width:36px; height:36px; border-radius:10px;">
                            <div>
                                <h5 style="font-size:14px; margin-bottom:2px;">${user.name}</h5>
                                <p style="font-size:11px; color:var(--text-secondary)">ID: ${user.id.toString().substring(0, 8)}...</p>
                            </div>
                        </div>
                    </td>
                    <td>
                        <div style="font-size:13px; margin-bottom:2px;">${user.email} ${verifyIcon}</div>
                        <div style="font-size:12px; color:var(--text-secondary)"><i class="fa-solid fa-phone"></i> ${user.phone || 'N/A'}</div>
                    </td>
                    <td>
                        <strong style="font-size:14px; color:var(--success)">₹${user.wallet_balance.toFixed(2)}</strong>
                    </td>
                    <td><span class="status-badge ${statusClass}">${statusText}</span></td>
                    <td><span style="font-size:13px; color:var(--text-secondary)">${joinDate}</span></td>
                    <td>
                        <button class="action-btn" title="View Details"><i class="fa-solid fa-eye"></i></button>
                        <button class="action-btn delete" title="Suspend"><i class="fa-solid fa-ban"></i></button>
                    </td>
                </tr>
            `;
        });
}

// ── Step 6: Ticket Stream ────────────────────────────────────────────────────
async function fetchTickets() {
    let tickets;
    try {
        const res = await fetch(`${BASE_URL}/admin/tickets`, {
            headers: { 'Authorization': `Bearer ${jwtToken}` }
        });
        if (!res.ok) throw new Error('tickets fetch failed');
        tickets = await res.json();
    } catch (e) {
        tickets = MOCK.tickets;
    }

        const container = document.getElementById('ticketStreamContainer');
        container.innerHTML = '';

        if (tickets.length === 0) {
            container.innerHTML = '<div class="empty-state">No tickets purchased today.</div>';
            return;
        }

        tickets.forEach(ticket => {
            const timeStr = new Date(ticket.issued_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });

            container.innerHTML += `
                <div style="background:rgba(255,255,255,0.03); border:1px solid var(--glass-border); padding:15px; border-radius:12px; display:flex; align-items:center; gap:15px; transition:all 0.2s;">
                    <div style="width:40px; height:40px; border-radius:10px; background:rgba(34, 197, 94, 0.15); color:var(--success); display:flex; justify-content:center; align-items:center; font-size:18px;">
                        <i class="fa-solid fa-qrcode"></i>
                    </div>
                    <div style="flex-grow:1;">
                        <div style="display:flex; justify-content:space-between; margin-bottom:4px;">
                            <strong style="font-size:14px;">Route ${ticket.route_id}</strong>
                            <span style="font-size:12px; color:var(--text-secondary)"><i class="fa-regular fa-clock"></i> ${timeStr}</span>
                        </div>
                        <div style="font-size:12px; color:var(--text-secondary);">
                            ${ticket.origin_stop} <i class="fa-solid fa-arrow-right" style="font-size:9px; margin:0 4px;"></i> ${ticket.destination_stop}
                        </div>
                    </div>
                    <div style="text-align:right;">
                        <h4 style="color:var(--success); margin:0;">₹${ticket.fare.toFixed(2)}</h4>
                        <span style="font-size:10px; color:var(--text-secondary); text-transform:uppercase;">${ticket.status}</span>
                    </div>
                </div>
            `;
        });

        // Render step 7 charts
        renderCharts(tickets);
}

// ── Step 7: Analytics Charts ─────────────────────────────────────────────────
let revChartInstance = null;
let routeChartInstance = null;

function renderCharts(tickets) {
    if (!tickets || tickets.length === 0) return;

    // Aggregate Data
    const routeCounts = {};
    let totalRev = 0;

    tickets.forEach(t => {
        routeCounts[t.route_id] = (routeCounts[t.route_id] || 0) + 1;
        totalRev += t.fare;
    });

    const revLabels = ['9 AM', '10 AM', '11 AM', '12 PM', '1 PM', '2 PM', 'Now'];
    const revData = [
        totalRev * 0.1, totalRev * 0.25, totalRev * 0.15,
        totalRev * 0.3, totalRev * 0.05, totalRev * 0.1, totalRev * 0.05
    ];

    const isLight = localStorage.getItem('nexride_theme') === 'light';
    const textColor = isLight ? '#333' : '#fff';
    const gridColor = isLight ? 'rgba(0,0,0,0.1)' : 'rgba(255,255,255,0.1)';

    if (revChartInstance) revChartInstance.destroy();
    const ctx1 = document.getElementById('revenueChart').getContext('2d');
    revChartInstance = new Chart(ctx1, {
        type: 'line',
        data: {
            labels: revLabels,
            datasets: [{
                label: 'Revenue (₹)',
                data: revData,
                borderColor: '#025ef5',
                backgroundColor: 'rgba(2, 94, 245, 0.2)',
                borderWidth: 3,
                fill: true,
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                y: { grid: { color: gridColor }, ticks: { color: textColor } },
                x: { grid: { display: false }, ticks: { color: textColor } }
            }
        }
    });

    // Show top 5 routes max
    const routeLabels = Object.keys(routeCounts).slice(0, 5).map(r => `Route ${r}`);
    const routeData = Object.values(routeCounts).slice(0, 5);

    if (routeChartInstance) routeChartInstance.destroy();
    const ctx2 = document.getElementById('routeChart').getContext('2d');
    routeChartInstance = new Chart(ctx2, {
        type: 'doughnut',
        data: {
            labels: routeLabels,
            datasets: [{
                data: routeData,
                backgroundColor: ['#025ef5', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6'],
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '70%',
            plugins: {
                legend: { position: 'bottom', labels: { color: textColor } }
            }
        }
    });

    // Overview Chart Implementation
    const ctxOverview = document.getElementById('overviewActivityChart');
    if (ctxOverview) {
        new Chart(ctxOverview.getContext('2d'), {
            type: 'bar',
            data: {
                labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                datasets: [{
                    label: 'Active Scans (Example)',
                    data: [120, 192, 153, 255, 224, 300, 281],
                    backgroundColor: 'rgba(2, 94, 245, 0.7)',
                    borderRadius: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    y: { grid: { color: gridColor }, ticks: { color: textColor } },
                    x: { grid: { display: false }, ticks: { color: textColor } }
                }
            }
        });
    }
}

// ── 3. Theme Toggle ──────────────────────────────────────────────────────────
function initTheme() {
    const isLight = localStorage.getItem('nexride_theme') === 'light';
    if (isLight) {
        document.body.classList.remove('dark-mode');
        document.body.classList.add('light-mode');
    }

    const themeBtn = document.getElementById('themeToggle');
    if (themeBtn) {
        themeBtn.addEventListener('click', (e) => {
            e.preventDefault();
            const body = document.body;
            if (body.classList.contains('light-mode')) {
                body.classList.remove('light-mode');
                body.classList.add('dark-mode');
                localStorage.setItem('nexride_theme', 'dark');
            } else {
                body.classList.remove('dark-mode');
                body.classList.add('light-mode');
                localStorage.setItem('nexride_theme', 'light');
            }
        });
    }
}
