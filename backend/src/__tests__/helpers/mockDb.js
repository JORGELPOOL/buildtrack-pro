const ADMIN_HASH = '$2b$10$1Et8T2JlGtk3ptQVzQFHLOgLbY7hEKwriVBuFJaOTsvhLZDt977JW';

function createInitialState() {
  return {
    users: [
      {
        id: 1,
        email: 'admin@buildtrack.com',
        password_hash: ADMIN_HASH,
        role: 'admin',
        created_at: new Date().toISOString()
      }
    ],
    projects: [],
    budgets: [],
    expenses: [],
    attendance: [],
    materials: [],
    photos: [],
    counters: {
      users: 2,
      projects: 1,
      expenses: 1,
      attendance: 1,
      materials: 1,
      photos: 1
    }
  };
}

let state = createInitialState();

function normalize(sql) {
  return sql.replace(/\s+/g, ' ').trim().toLowerCase();
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function nextId(key) {
  const id = state.counters[key];
  state.counters[key] += 1;
  return id;
}

function createTimestamp() {
  return new Date().toISOString();
}

function findProject(id) {
  return state.projects.find((project) => project.id === Number(id)) || null;
}

function removeProjectChildren(projectId) {
  const numericId = Number(projectId);
  state.budgets = state.budgets.filter((item) => item.project_id !== numericId);
  state.expenses = state.expenses.filter((item) => item.project_id !== numericId);
  state.attendance = state.attendance.filter((item) => item.project_id !== numericId);
  state.materials = state.materials.filter((item) => item.project_id !== numericId);
  state.photos = state.photos.filter((item) => item.project_id !== numericId);
}

const query = jest.fn(async (text, params = []) => {
  const sql = normalize(text);

  if (sql === 'select id, email, password_hash, role from users where email = $1') {
    const user = state.users.find((item) => item.email === String(params[0]).toLowerCase());
    return { rows: user ? [clone(user)] : [], rowCount: user ? 1 : 0 };
  }

  if (sql === 'insert into users (email, password_hash, role) values ($1, $2, $3) returning id, email, role, created_at') {
    const email = String(params[0]).toLowerCase();
    if (state.users.some((user) => user.email === email)) {
      const error = new Error('duplicate key value violates unique constraint');
      error.code = '23505';
      throw error;
    }

    const user = {
      id: nextId('users'),
      email,
      password_hash: params[1],
      role: params[2],
      created_at: createTimestamp()
    };
    state.users.push(user);
    return { rows: [clone({ id: user.id, email: user.email, role: user.role, created_at: user.created_at })], rowCount: 1 };
  }

  if (sql === 'select id from projects where id = $1') {
    const project = findProject(params[0]);
    return { rows: project ? [{ id: project.id }] : [], rowCount: project ? 1 : 0 };
  }

  if (sql === 'select id, name, description, client_name, start_date, end_date, status, created_at from projects order by created_at desc, id desc') {
    const rows = [...state.projects].sort((a, b) => (a.created_at < b.created_at ? 1 : -1) || b.id - a.id);
    return { rows: clone(rows), rowCount: rows.length };
  }

  if (sql.includes('insert into projects (name, description, client_name, start_date, end_date, status)')) {
    const project = {
      id: nextId('projects'),
      name: params[0],
      description: params[1],
      client_name: params[2],
      start_date: params[3],
      end_date: params[4],
      status: params[5],
      created_at: createTimestamp()
    };
    state.projects.push(project);
    return { rows: [clone(project)], rowCount: 1 };
  }

  if (sql === 'select id, name, description, client_name, start_date, end_date, status, created_at from projects where id = $1') {
    const project = findProject(params[0]);
    return { rows: project ? [clone(project)] : [], rowCount: project ? 1 : 0 };
  }

  if (sql.includes('update projects set name = $1, description = $2, client_name = $3, start_date = $4, end_date = $5, status = $6 where id = $7')) {
    const project = findProject(params[6]);
    if (!project) {
      return { rows: [], rowCount: 0 };
    }

    Object.assign(project, {
      name: params[0],
      description: params[1],
      client_name: params[2],
      start_date: params[3],
      end_date: params[4],
      status: params[5]
    });
    return { rows: [clone(project)], rowCount: 1 };
  }

  if (sql === 'delete from projects where id = $1 returning id') {
    const projectId = Number(params[0]);
    const index = state.projects.findIndex((project) => project.id === projectId);
    if (index === -1) {
      return { rows: [], rowCount: 0 };
    }

    state.projects.splice(index, 1);
    removeProjectChildren(projectId);
    return { rows: [{ id: projectId }], rowCount: 1 };
  }

  if (sql === 'select total_budget from budgets where project_id = $1') {
    const budget = state.budgets.find((item) => item.project_id === Number(params[0]));
    return { rows: budget ? [{ total_budget: String(budget.total_budget) }] : [], rowCount: budget ? 1 : 0 };
  }

  if (sql.includes('insert into budgets (project_id, total_budget) values ($1, $2) on conflict (project_id) do update set total_budget = excluded.total_budget, updated_at = now()')) {
    const projectId = Number(params[0]);
    const totalBudget = Number(params[1]);
    const budget = state.budgets.find((item) => item.project_id === projectId);
    if (budget) {
      budget.total_budget = totalBudget;
      budget.updated_at = createTimestamp();
    } else {
      state.budgets.push({
        project_id: projectId,
        total_budget: totalBudget,
        created_at: createTimestamp(),
        updated_at: createTimestamp()
      });
    }
    return { rows: [], rowCount: 1 };
  }

  if (sql === 'select coalesce(sum(amount), 0) as spent_amount from expenses where project_id = $1') {
    const spent = state.expenses
      .filter((item) => item.project_id === Number(params[0]))
      .reduce((sum, item) => sum + Number(item.amount), 0);
    return { rows: [{ spent_amount: String(spent) }], rowCount: 1 };
  }

  if (sql.includes('select id, project_id, category, description, amount, date, created_by, created_at from expenses where project_id = $1 order by date desc, id desc')) {
    const rows = state.expenses
      .filter((item) => item.project_id === Number(params[0]))
      .sort((a, b) => (a.date < b.date ? 1 : -1) || b.id - a.id);
    return { rows: clone(rows), rowCount: rows.length };
  }

  if (sql.includes('insert into expenses (project_id, category, description, amount, date, created_by)')) {
    const expense = {
      id: nextId('expenses'),
      project_id: Number(params[0]),
      category: params[1],
      description: params[2],
      amount: Number(params[3]),
      date: params[4],
      created_by: Number(params[5]),
      created_at: createTimestamp()
    };
    state.expenses.push(expense);
    return { rows: [clone(expense)], rowCount: 1 };
  }

  if (sql.includes('update expenses set category = $1, description = $2, amount = $3, date = $4 where id = $5')) {
    const expense = state.expenses.find((item) => item.id === Number(params[4]));
    if (!expense) {
      return { rows: [], rowCount: 0 };
    }

    Object.assign(expense, {
      category: params[0],
      description: params[1],
      amount: Number(params[2]),
      date: params[3]
    });
    return { rows: [clone(expense)], rowCount: 1 };
  }

  if (sql === 'delete from expenses where id = $1 returning id') {
    const expenseId = Number(params[0]);
    const index = state.expenses.findIndex((item) => item.id === expenseId);
    if (index === -1) {
      return { rows: [], rowCount: 0 };
    }

    state.expenses.splice(index, 1);
    return { rows: [{ id: expenseId }], rowCount: 1 };
  }

  if (sql.includes('select id, project_id, worker_name, date, check_in, check_out, hours_worked, notes from attendance where project_id = $1 order by date desc, id desc')) {
    const rows = state.attendance
      .filter((item) => item.project_id === Number(params[0]))
      .sort((a, b) => (a.date < b.date ? 1 : -1) || b.id - a.id);
    return { rows: clone(rows), rowCount: rows.length };
  }

  if (sql.includes('insert into attendance (project_id, worker_name, date, check_in, check_out, hours_worked, notes)')) {
    const record = {
      id: nextId('attendance'),
      project_id: Number(params[0]),
      worker_name: params[1],
      date: params[2],
      check_in: params[3],
      check_out: params[4],
      hours_worked: params[5],
      notes: params[6]
    };
    state.attendance.push(record);
    return { rows: [clone(record)], rowCount: 1 };
  }

  if (sql.includes('update attendance set worker_name = $1, date = $2, check_in = $3, check_out = $4, hours_worked = $5, notes = $6 where id = $7')) {
    const record = state.attendance.find((item) => item.id === Number(params[6]));
    if (!record) {
      return { rows: [], rowCount: 0 };
    }

    Object.assign(record, {
      worker_name: params[0],
      date: params[1],
      check_in: params[2],
      check_out: params[3],
      hours_worked: params[4],
      notes: params[5]
    });
    return { rows: [clone(record)], rowCount: 1 };
  }

  if (sql === 'delete from attendance where id = $1 returning id') {
    const attendanceId = Number(params[0]);
    const index = state.attendance.findIndex((item) => item.id === attendanceId);
    if (index === -1) {
      return { rows: [], rowCount: 0 };
    }

    state.attendance.splice(index, 1);
    return { rows: [{ id: attendanceId }], rowCount: 1 };
  }

  if (sql.includes('select id, project_id, name, quantity, unit, unit_cost, total_cost, supplier, status, date_ordered, date_delivered from materials where project_id = $1 order by date_ordered desc nulls last, id desc')) {
    const rows = state.materials
      .filter((item) => item.project_id === Number(params[0]))
      .sort((a, b) => {
        const aDate = a.date_ordered || '';
        const bDate = b.date_ordered || '';
        return (aDate < bDate ? 1 : -1) || b.id - a.id;
      });
    return { rows: clone(rows), rowCount: rows.length };
  }

  if (sql.includes('insert into materials (project_id, name, quantity, unit, unit_cost, total_cost, supplier, status, date_ordered, date_delivered)')) {
    const material = {
      id: nextId('materials'),
      project_id: Number(params[0]),
      name: params[1],
      quantity: Number(params[2]),
      unit: params[3],
      unit_cost: Number(params[4]),
      total_cost: Number(params[5]),
      supplier: params[6],
      status: params[7],
      date_ordered: params[8],
      date_delivered: params[9]
    };
    state.materials.push(material);
    return { rows: [clone(material)], rowCount: 1 };
  }

  if (sql.includes('update materials set name = $1, quantity = $2, unit = $3, unit_cost = $4, total_cost = $5, supplier = $6, status = $7, date_ordered = $8, date_delivered = $9 where id = $10')) {
    const material = state.materials.find((item) => item.id === Number(params[9]));
    if (!material) {
      return { rows: [], rowCount: 0 };
    }

    Object.assign(material, {
      name: params[0],
      quantity: Number(params[1]),
      unit: params[2],
      unit_cost: Number(params[3]),
      total_cost: Number(params[4]),
      supplier: params[5],
      status: params[6],
      date_ordered: params[7],
      date_delivered: params[8]
    });
    return { rows: [clone(material)], rowCount: 1 };
  }

  if (sql === 'delete from materials where id = $1 returning id') {
    const materialId = Number(params[0]);
    const index = state.materials.findIndex((item) => item.id === materialId);
    if (index === -1) {
      return { rows: [], rowCount: 0 };
    }

    state.materials.splice(index, 1);
    return { rows: [{ id: materialId }], rowCount: 1 };
  }

  if (sql.includes('select id, project_id, filename, original_name, caption, uploaded_by, created_at from photos where project_id = $1 order by created_at desc, id desc')) {
    const rows = state.photos
      .filter((item) => item.project_id === Number(params[0]))
      .sort((a, b) => (a.created_at < b.created_at ? 1 : -1) || b.id - a.id);
    return { rows: clone(rows), rowCount: rows.length };
  }

  if (sql.includes('insert into photos (project_id, filename, original_name, caption, uploaded_by)')) {
    const photo = {
      id: nextId('photos'),
      project_id: Number(params[0]),
      filename: params[1],
      original_name: params[2],
      caption: params[3],
      uploaded_by: Number(params[4]),
      created_at: createTimestamp()
    };
    state.photos.push(photo);
    return { rows: [clone(photo)], rowCount: 1 };
  }

  if (sql === 'delete from photos where id = $1 returning id, project_id, filename, original_name, caption, uploaded_by, created_at') {
    const photoId = Number(params[0]);
    const index = state.photos.findIndex((item) => item.id === photoId);
    if (index === -1) {
      return { rows: [], rowCount: 0 };
    }

    const [photo] = state.photos.splice(index, 1);
    return { rows: [clone(photo)], rowCount: 1 };
  }

  if (sql === 'select count(*)::int as total_records, coalesce(sum(hours_worked), 0) as total_hours from attendance where project_id = $1') {
    const rows = state.attendance.filter((item) => item.project_id === Number(params[0]));
    const totalHours = rows.reduce((sum, item) => sum + Number(item.hours_worked || 0), 0);
    return { rows: [{ total_records: rows.length, total_hours: String(totalHours) }], rowCount: 1 };
  }

  if (sql === 'select count(*)::int as total_items, coalesce(sum(total_cost), 0) as total_cost from materials where project_id = $1') {
    const rows = state.materials.filter((item) => item.project_id === Number(params[0]));
    const totalCost = rows.reduce((sum, item) => sum + Number(item.total_cost || 0), 0);
    return { rows: [{ total_items: rows.length, total_cost: String(totalCost) }], rowCount: 1 };
  }

  if (sql === 'select status, count(*)::int as count from materials where project_id = $1 group by status order by status') {
    const counts = state.materials
      .filter((item) => item.project_id === Number(params[0]))
      .reduce((accumulator, item) => {
        accumulator[item.status] = (accumulator[item.status] || 0) + 1;
        return accumulator;
      }, {});
    const rows = Object.keys(counts)
      .sort()
      .map((status) => ({ status, count: counts[status] }));
    return { rows, rowCount: rows.length };
  }

  if (sql === 'select count(*)::int as photo_count from photos where project_id = $1') {
    const count = state.photos.filter((item) => item.project_id === Number(params[0])).length;
    return { rows: [{ photo_count: count }], rowCount: 1 };
  }

  throw new Error(`Unhandled mock query: ${text}`);
});

function __reset() {
  state = createInitialState();
  query.mockClear();
}

function __getState() {
  return state;
}

function __seedUser(overrides = {}) {
  const user = {
    id: overrides.id || nextId('users'),
    email: overrides.email || `user${state.counters.users}@example.com`,
    password_hash: overrides.password_hash || ADMIN_HASH,
    role: overrides.role || 'staff',
    created_at: overrides.created_at || createTimestamp()
  };
  state.users.push(user);
  return clone(user);
}

function __seedProject(overrides = {}) {
  const project = {
    id: overrides.id || nextId('projects'),
    name: overrides.name || 'Tower Block A',
    description: overrides.description || 'Project description',
    client_name: overrides.client_name || 'Acme Client',
    start_date: overrides.start_date || '2026-01-01',
    end_date: overrides.end_date || '2026-12-31',
    status: overrides.status || 'planning',
    created_at: overrides.created_at || createTimestamp()
  };
  state.projects.push(project);
  return clone(project);
}

function __seedBudget(overrides = {}) {
  const budget = {
    project_id: Number(overrides.project_id),
    total_budget: Number(overrides.total_budget ?? 0),
    created_at: overrides.created_at || createTimestamp(),
    updated_at: overrides.updated_at || createTimestamp()
  };
  state.budgets = state.budgets.filter((item) => item.project_id !== budget.project_id);
  state.budgets.push(budget);
  return clone(budget);
}

function __seedExpense(overrides = {}) {
  const expense = {
    id: overrides.id || nextId('expenses'),
    project_id: Number(overrides.project_id),
    category: overrides.category || 'Labor',
    description: overrides.description || 'Expense description',
    amount: Number(overrides.amount ?? 0),
    date: overrides.date || '2026-02-01',
    created_by: Number(overrides.created_by ?? 1),
    created_at: overrides.created_at || createTimestamp()
  };
  state.expenses.push(expense);
  return clone(expense);
}

function __seedAttendance(overrides = {}) {
  const record = {
    id: overrides.id || nextId('attendance'),
    project_id: Number(overrides.project_id),
    worker_name: overrides.worker_name || 'John Worker',
    date: overrides.date || '2026-02-10',
    check_in: overrides.check_in || '08:00',
    check_out: overrides.check_out || '17:00',
    hours_worked: overrides.hours_worked ?? 9,
    notes: overrides.notes || null
  };
  state.attendance.push(record);
  return clone(record);
}

function __seedMaterial(overrides = {}) {
  const material = {
    id: overrides.id || nextId('materials'),
    project_id: Number(overrides.project_id),
    name: overrides.name || 'Cement',
    quantity: Number(overrides.quantity ?? 1),
    unit: overrides.unit || 'bags',
    unit_cost: Number(overrides.unit_cost ?? 1),
    total_cost: Number(overrides.total_cost ?? Number(overrides.quantity ?? 1) * Number(overrides.unit_cost ?? 1)),
    supplier: overrides.supplier || 'Supply Co',
    status: overrides.status || 'ordered',
    date_ordered: overrides.date_ordered || '2026-03-01',
    date_delivered: overrides.date_delivered || null
  };
  state.materials.push(material);
  return clone(material);
}

function __seedPhoto(overrides = {}) {
  const photo = {
    id: overrides.id || nextId('photos'),
    project_id: Number(overrides.project_id),
    filename: overrides.filename || 'existing-photo.txt',
    original_name: overrides.original_name || 'existing-photo.txt',
    caption: overrides.caption || null,
    uploaded_by: Number(overrides.uploaded_by ?? 1),
    created_at: overrides.created_at || createTimestamp()
  };
  state.photos.push(photo);
  return clone(photo);
}

module.exports = {
  pool: { query },
  query,
  __reset,
  __getState,
  __seedUser,
  __seedProject,
  __seedBudget,
  __seedExpense,
  __seedAttendance,
  __seedMaterial,
  __seedPhoto
};
