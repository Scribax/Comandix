const baseUrl = 'http://186.64.123.116/api/v1';

async function seed() {
  console.log('--- SEEDING VPS DATABASE ---');
  
  try {
    // 1. Login to get token
    console.log('Logging in...');
    const loginRes = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'admin@comandix.com', password: 'password123' })
    });
    
    if (!loginRes.ok) throw new Error('Login failed: ' + await loginRes.text());
    const { access_token } = await loginRes.json();
    console.log('Token acquired!');

    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${access_token}`
    };

    // 2. Create Sector
    console.log('Creating Sector...');
    const sectorRes = await fetch(`${baseUrl}/sectors`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ name: 'Salón Principal', isActive: true })
    });
    
    if (!sectorRes.ok) throw new Error('Sector failed: ' + await sectorRes.text());
    const sector = await sectorRes.json();
    console.log('Sector created:', sector.id);

    // 3. Create Tables
    console.log('Creating Tables...');
    const tables = [
      { name: 'Mesa 1', status: 'free', shape: 'square', posX: 100, posY: 100, width: 80, height: 80, rotation: 0, sectorId: sector.id },
      { name: 'Mesa 2', status: 'free', shape: 'square', posX: 250, posY: 100, width: 80, height: 80, rotation: 0, sectorId: sector.id },
      { name: 'Barra 1', status: 'free', shape: 'circle', posX: 100, posY: 250, width: 80, height: 80, rotation: 0, sectorId: sector.id },
    ];

    for (const t of tables) {
      await fetch(`${baseUrl}/tables`, {
        method: 'POST',
        headers,
        body: JSON.stringify(t)
      });
    }
    console.log('Tables created!');

    // 4. Create Category
    console.log('Creating Categories & Products...');
    const catRes = await fetch(`${baseUrl}/categories`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ name: 'Hamburguesas' })
    });
    const category = await catRes.json();

    // 5. Create Product
    await fetch(`${baseUrl}/products`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        name: 'Classic Burger',
        price: 8500,
        categoryId: category.id,
        isActive: true
      })
    });
    
    console.log('Products created!');
    console.log('--- SEEDING COMPLETE ---');
    
  } catch (err) {
    console.error('Error during seeding:', err);
  }
}

seed();
