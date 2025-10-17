/*
نظام إدارة الموظفين (Single-file React) — محدث
تغييرات رئيسية بناء على طلبك:
- أضفت مستخدم أدمن افتراضي (البريد و كلمة السر التي طلبتها).
- جعلت إضافة الموظفين مسموح بها فقط للأدمن.
- عند إضافة الموظف، الأدمن يحدد البريد، كلمة المرور، القسم، والدور، ويُسجل الموظف مباشرة في ذلك القسم.
- حسّنت واجهة المستخدم: هيرو جذاب، بطاقات مع تأثيرات hover و"دهشة"، تخطيط أنيق.

ملاحظة: هذا مشروع للواجهة (frontend) مع تخزين محلي محاكي. أنصح بربطه بـ Backend حقيقي (Node/Express + PostgreSQL) قبل التشغيل في بيئة إنتاج.
*/

import React, { useEffect, useState } from 'react';

export default function App() {
  // بيانات مبدئية (نماذج) — في التطبيق الحقيقي هذه تأتي من الخادم
  const initial = () => {
    const saved = localStorage.getItem('hr-system');
    if (saved) return JSON.parse(saved);

    const demo = {
      companies: [
        {
          id: 'comp-1',
          name: 'شركة الاختبار',
          domain: 'demo.company',
          admins: ['Yazeeddd81@gmail.com'],
        },
      ],
      departments: [
        { id: 'dept-hr', name: 'الموارد البشرية', companyId: 'comp-1' },
        { id: 'dept-dev', name: 'التطوير', companyId: 'comp-1' },
        { id: 'dept-sales', name: 'المبيعات', companyId: 'comp-1' },
      ],
      employees: [
        // الأدمن الافتراضي حسب طلبك
        {
          id: 'u-admin',
          companyId: 'comp-1',
          email: 'Yazeeddd81@gmail.com',
          password: 'Yazeed818',
          name: 'مسؤول النظام (Admin)',
          role: 'Admin',
          departmentId: null,
          salary: 0,
          locked: false,
        },
        {
          id: 'u-1',
          companyId: 'comp-1',
          email: 'gm@demo.company',
          password: 'P@ssword',
          name: 'المدير العام',
          role: 'General Manager',
          departmentId: null,
          salary: 15000,
          locked: false,
        },
        {
          id: 'u-2',
          companyId: 'comp-1',
          email: 'hr@demo.company',
          password: 'P@ssword',
          name: 'مسؤول الموارد البشرية',
          role: 'HR',
          departmentId: 'dept-hr',
          salary: 9000,
          locked: false,
        },
      ],
      tasks: [],
      leaves: [],
      payrollAdjustments: [],
    };

    localStorage.setItem('hr-system', JSON.stringify(demo));
    return demo;
  };

  const [data, setData] = useState(initial);
  const [currentCompanyId, setCurrentCompanyId] = useState(data.companies[0].id);
  const [currentUserId, setCurrentUserId] = useState('u-admin'); // يبدأ كمستخدم الأدمن الافتراضي
  const [ui, setUi] = useState({ view: 'dashboard', modal: null });

  useEffect(() => {
    localStorage.setItem('hr-system', JSON.stringify(data));
  }, [data]);

  // Helpers
  const company = data.companies.find((c) => c.id === currentCompanyId);
  const currentUser = data.employees.find((e) => e.id === currentUserId);

  const employeesOfCompany = data.employees.filter((e) => e.companyId === currentCompanyId);
  const departmentsOfCompany = data.departments.filter((d) => d.companyId === currentCompanyId);

  // CRUD — Companies / Departments / Employees
  function addDepartment(name) {
    const d = { id: 'dept-' + Date.now(), name, companyId: currentCompanyId };
    setData((s) => ({ ...s, departments: [...s.departments, d] }));
  }

  function addEmployee({ name, email, password, role, departmentId, salary }) {
    // قيد: فقط الأدمن يقدر يضيف موظفين
    if (!currentUser || currentUser.role !== 'Admin') {
      alert('فقط المستخدم صاحب دور Admin يقدر يضيف موظفين');
      return;
    }

    const e = {
      id: 'u-' + Date.now(),
      companyId: currentCompanyId,
      email,
      password,
      name,
      role,
      departmentId: departmentId || null,
      salary: Number(salary) || 0,
      locked: false,
    };
    setData((s) => ({ ...s, employees: [...s.employees, e] }));
  }

  function toggleLock(employeeId) {
    setData((s) => ({
      ...s,
      employees: s.employees.map((x) => (x.id === employeeId ? { ...x, locked: !x.locked } : x)),
    }));
  }

  function updateEmployee(employeeId, fields) {
    setData((s) => ({
      ...s,
      employees: s.employees.map((x) => (x.id === employeeId ? { ...x, ...fields } : x)),
    }));
  }

  // Tasks
  function sendTask({ title, desc, assigneeId }) {
    const t = {
      id: 't-' + Date.now(),
      title,
      desc,
      assignerId: currentUserId,
      assigneeId,
      companyId: currentCompanyId,
      status: 'open',
      createdAt: new Date().toISOString(),
    };
    setData((s) => ({ ...s, tasks: [...s.tasks, t] }));
  }

  function completeTask(taskId) {
    setData((s) => ({ ...s, tasks: s.tasks.map((t) => (t.id === taskId ? { ...t, status: 'done' } : t)) }));
  }

  // Payroll adjustments
  function addAdjustment({ employeeId, amount, type, reason }) {
    const adj = { id: 'adj-' + Date.now(), employeeId, amount: Number(amount), type, reason };
    setData((s) => ({ ...s, payrollAdjustments: [...s.payrollAdjustments, adj] }));
  }

  // Leaves workflow
  function requestLeave({ employeeId, from, to, reason }) {
    const days = Math.max(1, Math.ceil((new Date(to) - new Date(from)) / (1000 * 60 * 60 * 24)) + 1);
    const leave = {
      id: 'lv-' + Date.now(),
      employeeId,
      companyId: currentCompanyId,
      from,
      to,
      days,
      reason,
      status: 'pending_dept',
      approvals: { dept: false, hr: false, gm: false },
      createdAt: new Date().toISOString(),
    };
    setData((s) => ({ ...s, leaves: [...s.leaves, leave] }));
  }

  function approveLeave(leaveId, stage) {
    setData((s) => ({
      ...s,
      leaves: s.leaves.map((l) => {
        if (l.id !== leaveId) return l;
        const next = { ...l };
        if (stage === 'dept') {
          next.approvals.dept = true;
          next.status = 'pending_hr';
        } else if (stage === 'hr') {
          next.approvals.hr = true;
          next.status = 'pending_gm';
        } else if (stage === 'gm') {
          next.approvals.gm = true;
          next.status = 'approved';
        }
        return next;
      }),
    }));
  }

  function rejectLeave(leaveId) {
    setData((s) => ({ ...s, leaves: s.leaves.map((l) => (l.id === leaveId ? { ...l, status: 'rejected' } : l)) }));
  }

  // Simple auth switcher (simulate logging as a user)
  function loginAs(userId) {
    setCurrentUserId(userId);
    setUi({ view: 'dashboard', modal: null });
  }

  // UI small components
  const RoleBadge = ({ role }) => (
    <span className="px-2 py-1 rounded text-sm border">{role}</span>
  );

  // Render
  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-100 to-white p-6 font-sans">
      <div className="max-w-7xl mx-auto">
        {/* HERO */}
        <div className="rounded-2xl p-6 mb-6 bg-gradient-to-r from-indigo-600 to-pink-500 text-white shadow-2xl transform-gpu hover:scale-[1.01] transition-all">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-extrabold">نظام إدارة الموظفين — لوحة تحكم متكاملة</h1>
              <p className="mt-2 text-sm opacity-90">إدارة الموظفين، الموافقات، المهام والرواتب — كل شيء في مكان واحد وبواجهة جذابة.</p>
            </div>
            <div className="text-right">
              <div className="text-xs opacity-90">تسجيل الدخول كمستخدم محاكاة</div>
              <select className="mt-2 p-2 rounded text-black" value={currentUserId} onChange={(e) => loginAs(e.target.value)}>
                {employeesOfCompany.map((u) => (
                  <option key={u.id} value={u.id}>{u.name} — {u.role}</option>
                ))}
              </select>
            </div>
          </div>
        </div>

        <div className="bg-white shadow-lg rounded-2xl overflow-hidden flex">
          <aside className="w-72 border-r p-6 bg-gradient-to-b from-white to-gray-50">
            <h2 className="text-lg font-bold mb-2">{company.name}</h2>
            <p className="text-sm mb-3 text-gray-600">دومين: {company.domain}</p>

            <div className="mb-4">
              <label className="block text-xs text-gray-500">اختر الشركة</label>
              <select className="w-full border p-2 rounded mt-1" value={currentCompanyId} onChange={(e) => setCurrentCompanyId(e.target.value)}>
                {data.companies.map((c) => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
            </div>

            <nav className="space-y-2">
              <button className="w-full text-right p-2 rounded hover:bg-gray-100" onClick={() => setUi((s) => ({ ...s, view: 'dashboard' }))}>لوحة القيادة</button>
              <button className="w-full text-right p-2 rounded hover:bg-gray-100" onClick={() => setUi((s) => ({ ...s, view: 'employees' }))}>الموظفين</button>
              <button className="w-full text-right p-2 rounded hover:bg-gray-100" onClick={() => setUi((s) => ({ ...s, view: 'departments' }))}>الأقسام</button>
              <button className="w-full text-right p-2 rounded hover:bg-gray-100" onClick={() => setUi((s) => ({ ...s, view: 'tasks' }))}>المهام</button>
              <button className="w-full text-right p-2 rounded hover:bg-gray-100" onClick={() => setUi((s) => ({ ...s, view: 'leaves' }))}>طلبات الإجازة</button>
              <button className="w-full text-right p-2 rounded hover:bg-gray-100" onClick={() => setUi((s) => ({ ...s, view: 'payroll' }))}>الرواتب والتعديلات</button>
            </nav>

            <div className="mt-6 text-xs text-gray-600">
              <div>المستخدم الحالي:</div>
              <div className="font-medium">{currentUser.name} — <RoleBadge role={currentUser.role} /></div>
            </div>
          </aside>

          <main className="flex-1 p-8">
            {/* Views */}
            {ui.view === 'dashboard' && (
              <section>
                <div className="grid grid-cols-3 gap-6 mb-6">
                  <div className="p-6 rounded-xl bg-white shadow hover:shadow-xl transition"> 
                    <div className="text-sm text-gray-500">عدد الموظفين</div>
                    <div className="text-3xl font-bold mt-2">{employeesOfCompany.length}</div>
                  </div>
                  <div className="p-6 rounded-xl bg-white shadow hover:shadow-xl transition"> 
                    <div className="text-sm text-gray-500">مهام مفتوحة</div>
                    <div className="text-3xl font-bold mt-2">{data.tasks.filter(t => t.companyId === currentCompanyId && t.status === 'open').length}</div>
                  </div>
                  <div className="p-6 rounded-xl bg-white shadow hover:shadow-xl transition"> 
                    <div className="text-sm text-gray-500">طلبات إجازة قيد المعالجة</div>
                    <div className="text-3xl font-bold mt-2">{data.leaves.filter(l => l.companyId === currentCompanyId && l.status !== 'approved' && l.status !== 'rejected').length}</div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-6">
                  <div className="p-6 rounded-xl bg-white shadow">
                    <h3 className="font-semibold mb-4">آخر الموظفين</h3>
                    <ul className="space-y-3">
                      {employeesOfCompany.slice(-6).reverse().map((u) => (
                        <li key={u.id} className="flex justify-between items-center p-3 border rounded hover:bg-gray-50 transition">
                          <div>
                            <div className="font-medium">{u.name} {u.locked && <span className="text-red-500">(مقفل)</span>}</div>
                            <div className="text-xs text-gray-500">{u.email} — {departmentsOfCompany.find(d => d.id === u.departmentId)?.name || 'بدون قسم'}</div>
                          </div>
                          <div className="text-sm">{u.salary} ر.س</div>
                        </li>
                      ))}
                    </ul>
                  </div>

                  <div className="p-6 rounded-xl bg-white shadow">
                    <h3 className="font-semibold mb-4">تدفق الإجازات القادمة</h3>
                    <ul className="space-y-3">
                      {data.leaves.filter(l => l.companyId === currentCompanyId && l.status !== 'approved' && l.status !== 'rejected').slice(0,5).map((l) => {
                        const emp = data.employees.find(e => e.id === l.employeeId);
                        return (
                          <li key={l.id} className="p-3 border rounded">
                            <div className="flex justify-between">
                              <div>
                                <div className="font-medium">{emp?.name} — {emp?.email}</div>
                                <div className="text-xs">من {l.from} إلى {l.to} ({l.days} يوم)</div>
                                <div className="text-xs text-gray-600">الحالة: {l.status}</div>
                              </div>
                              <div className="space-y-1">
                                {currentUser.role === 'Department Manager' && departmentsOfCompany.some(d => d.id === currentUser.departmentId) && emp.departmentId === currentUser.departmentId && l.status === 'pending_dept' && (
                                  <>
                                    <button className="px-3 py-1 rounded bg-green-600 text-white text-sm" onClick={() => approveLeave(l.id, 'dept')}>وافق</button>
                                    <button className="px-3 py-1 rounded bg-red-500 text-white text-sm" onClick={() => rejectLeave(l.id)}>رفض</button>
                                  </>
                                )}
                                {currentUser.role === 'HR' && l.status === 'pending_hr' && (
                                  <>
                                    <button className="px-3 py-1 rounded bg-green-600 text-white text-sm" onClick={() => approveLeave(l.id, 'hr')}>الموارد البشرية — موافق</button>
                                    <button className="px-3 py-1 rounded bg-red-500 text-white text-sm" onClick={() => rejectLeave(l.id)}>رفض</button>
                                  </>
                                )}
                                {currentUser.role === 'General Manager' && l.status === 'pending_gm' && (
                                  <>
                                    <button className="px-3 py-1 rounded bg-green-600 text-white text-sm" onClick={() => approveLeave(l.id, 'gm')}>اعتماد المدير العام</button>
                                    <button className="px-3 py-1 rounded bg-red-500 text-white text-sm" onClick={() => rejectLeave(l.id)}>رفض</button>
                                  </>
                                )}
                              </div>
                            </div>
                          </li>
                        );
                      })}
                    </ul>
                  </div>
                </div>
              </section>
            )}

            {ui.view === 'departments' && (
              <section>
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-xl font-semibold">الأقسام</h2>
                  <div>
                    <AddDepartmentForm onAdd={(name) => addDepartment(name)} />
                  </div>
                </div>
                <div className="grid grid-cols-3 gap-6">
                  {departmentsOfCompany.map((d) => (
                    <div key={d.id} className="p-4 rounded-xl bg-white shadow hover:scale-[1.01] transition">
                      <div className="font-medium">{d.name}</div>
                      <div className="text-xs text-gray-500">{data.employees.filter(e => e.departmentId === d.id).length} موظف</div>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {ui.view === 'employees' && (
              <section>
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-xl font-semibold">الموظفين</h2>
                  <div>
                    {currentUser.role === 'Admin' ? (
                      <AddEmployeeForm departments={departmentsOfCompany} onAdd={addEmployee} />
                    ) : (
                      <div className="text-sm text-gray-500">فقط الأدمن يقدر يضيف موظفين — سجل كـ Admin لإضافة موظفين</div>
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-1 gap-4">
                  {employeesOfCompany.map((u) => (
                    <div key={u.id} className="p-4 rounded-xl bg-white shadow flex justify-between items-center hover:shadow-xl transition">
                      <div>
                        <div className="font-medium">{u.name} {u.locked && <span className="text-red-500">(مقفل)</span>}</div>
                        <div className="text-xs text-gray-500">{u.email} — {u.role} — {departmentsOfCompany.find(d => d.id === u.departmentId)?.name || 'بدون قسم'}</div>
                        <div className="text-xs text-gray-500">الراتب: {u.salary} ر.س</div>
                      </div>
                      <div className="space-x-2">
                        <button className="px-3 py-1 border rounded" onClick={() => toggleLock(u.id)}>{u.locked ? 'فتح الحساب' : 'قفل الحساب'}</button>
                        <button className="px-3 py-1 border rounded" onClick={() => setUi((s) => ({ ...s, modal: { type: 'edit-employee', id: u.id } }))}>تعديل</button>
                        <button className="px-3 py-1 bg-blue-600 text-white rounded" onClick={() => setUi((s) => ({ ...s, modal: { type: 'send-task', assigneeId: u.id } }))}>أرسل مهمة</button>
                        <button className="px-3 py-1 bg-yellow-500 text-white rounded" onClick={() => setUi((s) => ({ ...s, modal: { type: 'request-leave', employeeId: u.id } }))}>طلب إجازة</button>
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {ui.view === 'tasks' && (
              <section>
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-xl font-semibold">المهام</h2>
                </div>
                <div className="space-y-3">
                  {data.tasks.filter(t => t.companyId === currentCompanyId).map((t) => (
                    <div key={t.id} className="p-3 rounded-xl bg-white shadow flex justify-between items-center">
                      <div>
                        <div className="font-medium">{t.title}</div>
                        <div className="text-xs text-gray-500">إلى: {data.employees.find(e => e.id === t.assigneeId)?.name} — حالة: {t.status}</div>
                        <div className="text-xs">{t.desc}</div>
                      </div>
                      <div>
                        {t.status !== 'done' && currentUser.id === t.assigneeId && (
                          <button className="px-3 py-1 bg-green-600 text-white rounded" onClick={() => completeTask(t.id)}>تم</button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {ui.view === 'leaves' && (
              <section>
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-xl font-semibold">طلبات الإجازة</h2>
                </div>
                <div className="space-y-3">
                  {data.leaves.filter(l => l.companyId === currentCompanyId).map((l) => {
                    const emp = data.employees.find(e => e.id === l.employeeId);
                    return (
                      <div key={l.id} className="p-3 rounded-xl bg-white shadow flex justify-between items-center">
                        <div>
                          <div className="font-medium">{emp?.name} — من {l.from} إلى {l.to} ({l.days} يوم)</div>
                          <div className="text-xs text-gray-500">السبب: {l.reason}</div>
                          <div className="text-xs">الحالة: {l.status}</div>
                        </div>
                        <div>
                          {/* Actions conditioned by role */}
                          {currentUser.role === 'Department Manager' && currentUser.departmentId === emp.departmentId && l.status === 'pending_dept' && (
                            <>
                              <button className="px-3 py-1 bg-green-600 text-white rounded mr-2" onClick={() => approveLeave(l.id, 'dept')}>موافقة القسم</button>
                              <button className="px-3 py-1 bg-red-500 text-white rounded" onClick={() => rejectLeave(l.id)}>رفض</button>
                            </>
                          )}
                          {currentUser.role === 'HR' && l.status === 'pending_hr' && (
                            <>
                              <button className="px-3 py-1 bg-green-600 text-white rounded mr-2" onClick={() => approveLeave(l.id, 'hr')}>موارد بشرية — موافق</button>
                              <button className="px-3 py-1 bg-red-500 text-white rounded" onClick={() => rejectLeave(l.id)}>رفض</button>
                            </>
                          )}
                          {currentUser.role === 'General Manager' && l.status === 'pending_gm' && (
                            <>
                              <button className="px-3 py-1 bg-green-600 text-white rounded mr-2" onClick={() => approveLeave(l.id, 'gm')}>اعتماد المدير العام</button>
                              <button className="px-3 py-1 bg-red-500 text-white rounded" onClick={() => rejectLeave(l.id)}>رفض</button>
                            </>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </section>
            )}

            {ui.view === 'payroll' && (
              <section>
                <div className="mb-4 flex justify-between items-center">
                  <h2 className="text-xl font-semibold">الرواتب والتعديلات</h2>
                </div>
                <div className="space-y-3">
                  {employeesOfCompany.map((e) => (
                    <div key={e.id} className="p-3 rounded-xl bg-white shadow flex justify-between items-center">
                      <div>
                        <div className="font-medium">{e.name}</div>
                        <div className="text-xs text-gray-500">الراتب الأساسي: {e.salary} ر.س</div>
                        <div className="text-xs text-gray-500">تعديلات: {data.payrollAdjustments.filter(a => a.employeeId === e.id).length}</div>
                      </div>
                      <div>
                        <button className="px-3 py-1 border rounded mr-2" onClick={() => setUi((s) => ({ ...s, modal: { type: 'pay-adjust', employeeId: e.id } }))}>أضف تعديل</button>
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}

          </main>
        </div>
      </div>

      {/* Modals */}
      {ui.modal?.type === 'edit-employee' && (
        <Modal onClose={() => setUi((s) => ({ ...s, modal: null }))}>
          <EditEmployeeForm employee={data.employees.find(e => e.id === ui.modal.id)} departments={departmentsOfCompany} onSave={(id, fields) => { updateEmployee(id, fields); setUi((s) => ({ ...s, modal: null })); }} />
        </Modal>
      )}

      {ui.modal?.type === 'send-task' && (
        <Modal onClose={() => setUi((s) => ({ ...s, modal: null }))}>
          <SendTaskForm assigneeId={ui.modal.assigneeId} employees={employeesOfCompany} onSend={(payload) => { sendTask(payload); setUi((s) => ({ ...s, modal: null })); }} />
        </Modal>
      )}

      {ui.modal?.type === 'request-leave' && (
        <Modal onClose={() => setUi((s) => ({ ...s, modal: null }))}>
          <RequestLeaveForm employeeId={ui.modal.employeeId} onRequest={(payload) => { requestLeave(payload); setUi((s) => ({ ...s, modal: null })); }} />
        </Modal>
      )}

      {ui.modal?.type === 'pay-adjust' && (
        <Modal onClose={() => setUi((s) => ({ ...s, modal: null }))}>
          <PayAdjustForm employeeId={ui.modal.employeeId} onAdd={(payload) => { addAdjustment(payload); setUi((s) => ({ ...s, modal: null })); }} />
        </Modal>
      )}

    </div>
  );
}

/* ---------- مكونات فرعية ---------- */
function Modal({ children, onClose }) {
  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-40">
      <div className="bg-white p-4 rounded w-11/12 md:w-2/3">
        <div className="flex justify-end mb-2"><button className="text-sm" onClick={onClose}>إغلاق</button></div>
        {children}
      </div>
    </div>
  );
}

function AddDepartmentForm({ onAdd }) {
  const [name, setName] = useState('');
  return (
    <div className="flex items-center space-x-2">
      <input className="border p-2 rounded" placeholder="اسم القسم" value={name} onChange={(e) => setName(e.target.value)} />
      <button className="px-3 py-2 bg-green-600 text-white rounded" onClick={() => { if (!name) return alert('اكتب اسم'); onAdd(name); setName(''); }}>إضافة قسم</button>
    </div>
  );
}

function AddEmployeeForm({ departments, onAdd }) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('Employee');
  const [departmentId, setDepartmentId] = useState('');
  const [salary, setSalary] = useState('5000');
  return (
    <div className="flex items-center space-x-2">
      <input className="border p-2 rounded" placeholder="الاسم" value={name} onChange={(e) => setName(e.target.value)} />
      <input className="border p-2 rounded" placeholder="البريد" value={email} onChange={(e) => setEmail(e.target.value)} />
      <input className="border p-2 rounded w-40" placeholder="كلمة المرور" value={password} onChange={(e) => setPassword(e.target.value)} />
      <select className="border p-2 rounded" value={role} onChange={(e) => setRole(e.target.value)}>
        <option>Employee</option>
        <option>Department Manager</option>
        <option>HR</option>
        <option>General Manager</option>
        <option>Deputy Manager</option>
      </select>
      <select className="border p-2 rounded" value={departmentId} onChange={(e) => setDepartmentId(e.target.value)}>
        <option value="">بدون قسم</option>
        {departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
      </select>
      <input className="border p-2 rounded w-24" placeholder="راتب" value={salary} onChange={(e) => setSalary(e.target.value)} />
      <button className="px-3 py-2 bg-blue-600 text-white rounded" onClick={() => { if (!name || !email || !password) return alert('ادخل الاسم والبريد وكلمة المرور'); onAdd({ name, email, password, role, departmentId, salary }); setName(''); setEmail(''); setPassword(''); }}>أضف</button>
    </div>
  );
}

function EditEmployeeForm({ employee, departments, onSave }) {
  const [name, setName] = useState(employee?.name || '');
  const [role, setRole] = useState(employee?.role || 'Employee');
  const [departmentId, setDepartmentId] = useState(employee?.departmentId || '');
  const [salary, setSalary] = useState(employee?.salary || 0);
  if (!employee) return null;
  return (
    <div>
      <h3 className="font-semibold mb-2">تعديل موظف</h3>
      <div className="grid grid-cols-2 gap-2">
        <input className="border p-2 rounded" value={name} onChange={(e) => setName(e.target.value)} />
        <select className="border p-2 rounded" value={role} onChange={(e) => setRole(e.target.value)}>
          <option>Employee</option>
          <option>Department Manager</option>
          <option>HR</option>
          <option>General Manager</option>
          <option>Deputy Manager</option>
        </select>
        <select className="border p-2 rounded" value={departmentId} onChange={(e) => setDepartmentId(e.target.value)}>
          <option value="">بدون قسم</option>
          {departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
        </select>
        <input className="border p-2 rounded" value={salary} onChange={(e) => setSalary(e.target.value)} />
      </div>
      <div className="mt-3 flex justify-end">
        <button className="px-3 py-2 bg-blue-600 text-white rounded" onClick={() => onSave(employee.id, { name, role, departmentId: departmentId || null, salary })}>حفظ</button>
      </div>
    </div>
  );
}

function SendTaskForm({ assigneeId, employees, onSend }) {
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [assignee, setAssignee] = useState(assigneeId || (employees[0] && employees[0].id));
  return (
    <div>
      <h3 className="font-semibold mb-2">ارسال مهمة</h3>
      <input className="border p-2 rounded w-full mb-2" placeholder="عنوان المهمة" value={title} onChange={(e) => setTitle(e.target.value)} />
      <textarea className="border p-2 rounded w-full mb-2" placeholder="تفاصيل" value={desc} onChange={(e) => setDesc(e.target.value)} />
      <select className="border p-2 rounded w-full mb-2" value={assignee} onChange={(e) => setAssignee(e.target.value)}>
        {employees.map(u => <option key={u.id} value={u.id}>{u.name} — {u.role}</option>)}
      </select>
      <div className="flex justify-end">
        <button className="px-3 py-2 bg-blue-600 text-white rounded" onClick={() => { if (!title) return alert('اكتب عنوان'); onSend({ title, desc, assigneeId: assignee }); }}>ارسال</button>
      </div>
    </div>
  );
}

function RequestLeaveForm({ employeeId, onRequest }) {
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [reason, setReason] = useState('');
  return (
    <div>
      <h3 className="font-semibold mb-2">طلب إجازة</h3>
      <div className="grid grid-cols-2 gap-2">
        <input type="date" className="border p-2 rounded" value={from} onChange={(e) => setFrom(e.target.value)} />
        <input type="date" className="border p-2 rounded" value={to} onChange={(e) => setTo(e.target.value)} />
      </div>
      <textarea className="border p-2 rounded w-full my-2" placeholder="سبب الإجازة" value={reason} onChange={(e) => setReason(e.target.value)} />
      <div className="flex justify-end">
        <button className="px-3 py-2 bg-blue-600 text-white rounded" onClick={() => { if (!from || !to) return alert('اختر من وإلى'); onRequest({ employeeId, from, to, reason }); }}>أطلب</button>
      </div>
    </div>
  );
}

function PayAdjustForm({ employeeId, onAdd }) {
  const [amount, setAmount] = useState(0);
  const [type, setType] = useState('deduction');
  const [reason, setReason] = useState('');
  return (
    <div>
      <h3 className="font-semibold mb-2">إضافة تعديل على الراتب</h3>
      <input className="border p-2 rounded w-full mb-2" placeholder="المبلغ" value={amount} onChange={(e) => setAmount(e.target.value)} />
      <select className="border p-2 rounded w-full mb-2" value={type} onChange={(e) => setType(e.target.value)}>
        <option value="deduction">خصم</option>
        <option value="bonus">زيادة</option>
      </select>
      <input className="border p-2 rounded w-full mb-2" placeholder="السبب" value={reason} onChange={(e) => setReason(e.target.value)} />
      <div className="flex justify-end">
        <button className="px-3 py-2 bg-blue-600 text-white rounded" onClick={() => { if (!amount) return alert('اكتب مبلغ'); onAdd({ employeeId, amount, type, reason }); }}>أضف</button>
      </div>
    </div>
  );
}

/* ---------- مواصفات API & قاعدة البيانات (مقترح) ----------
مذكور داخل الملف الأصلي — يمكنني توليد Backend كامل وربطه.
*/
