const API_BASE = ""; // Relative to the server

async function apiGet(endpoint) {
    try {
        const res = await fetch(`${API_BASE}/api/${endpoint}`);
        return await res.json();
    } catch (e) {
        console.error(`Error fetching ${endpoint}:`, e);
        return [];
    }
}

async function apiPost(endpoint, data) {
    try {
        await fetch(`${API_BASE}/api/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        return { success: true };
    } catch (e) {
        console.error(`Error posting to ${endpoint}:`, e);
        return { success: false };
    }
}
