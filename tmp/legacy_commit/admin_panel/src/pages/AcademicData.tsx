import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { BookOpen, GraduationCap, Award, Plus, Edit2, Trash2, X, Check, Search, CalendarClock } from 'lucide-react';

type Tab = 'course_metadata' | 'scholarship_policies' | 'grade_scale' | 'active_semester';

export function AcademicData() {
  const [activeTab, setActiveTab] = useState<Tab>('course_metadata');
  const [data, setData] = useState<any[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(false);
  const [isEditing, setIsEditing] = useState<any>(null);
  const [editForm, setEditForm] = useState<any>({});
  const [isAdding, setIsAdding] = useState(false);

  useEffect(() => {
    fetchData(activeTab);
    setSearchTerm('');
  }, [activeTab]);

  async function fetchData(table: Tab) {
    setLoading(true);
    let query = supabase.from(table).select('*');
    if (table === 'course_metadata') query = query.order('code');
    if (table === 'grade_scale') query = query.order('point', { ascending: false });

    const { data: result, error } = await query;
    if (!error && result) {
      setData(result);
    }
    setLoading(false);
    setIsEditing(null);
    setIsAdding(false);
  }

  const handleEdit = (item: any) => {
    setIsEditing(item);
    setEditForm({ ...item });
  };

  const handleSave = async (table: Tab) => {
    let pkField = 'id';
    if (table === 'course_metadata') pkField = 'code';
    if (table === 'grade_scale') pkField = 'grade';
    if (table === 'active_semester') pkField = 'track';

    let error;

    if (isAdding) {
      const { error: insertError } = await supabase.from(table).insert([editForm]);
      error = insertError;
    } else {
      const { error: updateError } = await supabase
        .from(table)
        .update(editForm)
        .eq(pkField, isEditing[pkField]);
      error = updateError;
    }

    if (!error) {
      fetchData(activeTab);
    } else {
      alert(`Error saving: ${error.message}`);
    }
  };

  const handleDelete = async (item: any, table: Tab) => {
    if (!confirm('Are you sure you want to delete this record?')) return;
    
    let pkField = 'id';
    if (table === 'course_metadata') pkField = 'code';
    if (table === 'grade_scale') pkField = 'grade';
    if (table === 'active_semester') pkField = 'track';

    const { error } = await supabase.from(table).delete().eq(pkField, item[pkField]);

    if (!error) {
      fetchData(activeTab);
    } else {
      alert(`Error deleting: ${error.message}`);
    }
  };

  const columns: Record<Tab, { key: string, label: string, type: 'text' | 'number' | 'date' }[]> = {
    course_metadata: [
      { key: 'code', label: 'Course Code', type: 'text' },
      { key: 'name', label: 'Course Name', type: 'text' },
      { key: 'credit_val', label: 'Credits', type: 'number' },
      { key: 'equivalent_code', label: 'Equivalent Code', type: 'text' }
    ],
    scholarship_policies: [
      { key: 'department_code', label: 'Dept', type: 'text' },
      { key: 'min_yearly_credits', label: 'Min Credits', type: 'number' },
      { key: 'merit_cgpa_min', label: 'Merit CGPA (Min-Max)', type: 'number' },
      { key: 'deans_cgpa_min', label: 'Deans CGPA (Min-Max)', type: 'number' },
      { key: 'medha_cgpa_min', label: 'Medha CGPA (Min-Max)', type: 'number' }
    ],
    grade_scale: [
      { key: 'grade', label: 'Grade', type: 'text' },
      { key: 'point', label: 'Points', type: 'number' },
      { key: 'min_score', label: 'Min Score (%)', type: 'number' },
      { key: 'description', label: 'Description', type: 'text' },
      { key: 'policy', label: 'Policy Profile', type: 'text' }
      ],
      active_semester: [
        { key: 'track', label: 'Track', type: 'text' },
        { key: 'current_semester_code', label: 'Current Sem', type: 'text' },
        { key: 'next_semester_code', label: 'Next Sem', type: 'text' },
        { key: 'classes_start_date', label: 'Class Start', type: 'date' },
        { key: 'classes_end_date', label: 'Class End', type: 'date' },
        { key: 'advising_start_date', label: 'Advising Start', type: 'date' },
        { key: 'advising_end_date', label: 'Advising End', type: 'date' },
        { key: 'final_exam_start', label: 'Finals Start', type: 'date' },
        { key: 'final_exam_end', label: 'Finals End', type: 'date' },
        { key: 'grade_submission_start', label: 'Grade Sub Start', type: 'date' },
      ]
    };

    const filteredData = data.filter(row =>
      Object.values(row).some(val =>
        String(val).toLowerCase().includes(searchTerm.toLowerCase())
      )
    );

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Academic Data</h1>
          <p className="text-gray-500 mt-1">Manage global course metadata, grade scales, and scholarship rules.</p>
        </div>
        <div className="flex gap-3 items-center">
          <div className="relative">
            <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search records..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none w-64 transition-all"
            />
          </div>
          <button
            onClick={() => {
              setIsAdding(true);
              setIsEditing({});
              setEditForm({});
            }}
            className="flex items-center gap-2 bg-indigo-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-indigo-700 transition"
          >
            <Plus className="w-4 h-4" /> Add Record
          </button>
        </div>
      </div>

      <div className="flex gap-2 border-b border-gray-200">
        {[
          { id: 'course_metadata', label: 'Course Metadata', icon: BookOpen },
          { id: 'grade_scale', label: 'Grade Scale', icon: GraduationCap },
          { id: 'scholarship_policies', label: 'Scholarship Policies', icon: Award },
            { id: 'active_semester', label: 'Active Semester', icon: CalendarClock }
          ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as Tab)}
            className={`flex items-center gap-2 px-4 py-3 font-semibold text-sm transition-colors border-b-2 ${
              activeTab === tab.id ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-gray-500 hover:text-gray-800'
            }`}
          >
            <tab.icon className="w-4 h-4" />
            {tab.label}
          </button>
        ))}
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Loading data...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  {columns[activeTab].map(col => (
                    <th key={col.key} className="px-6 py-3 text-xs font-bold text-gray-500 uppercase tracking-wider">
                      {col.label}
                    </th>
                  ))}
                  <th className="px-6 py-3 text-xs font-bold text-gray-500 uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {isAdding && (
                  <tr className="bg-indigo-50/50">
                    {columns[activeTab].map(col => (
                      <td key={col.key} className="px-6 py-4">
                        <input
                          type={col.type}
                          value={editForm[col.key] || ''}
                          onChange={(e) => setEditForm({ ...editForm, [col.key]: e.target.value })}
                          className="w-full p-2 text-sm border border-indigo-200 rounded focus:ring-2 focus:ring-indigo-500 outline-none"
                          placeholder={col.label}
                        />
                      </td>
                    ))}
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button onClick={() => handleSave(activeTab)} className="p-1.5 bg-emerald-100 text-emerald-700 rounded hover:bg-emerald-200"><Check className="w-4 h-4" /></button>
                        <button onClick={() => {setIsAdding(false); setIsEditing(null);}} className="p-1.5 bg-gray-100 text-gray-700 rounded hover:bg-gray-200"><X className="w-4 h-4" /></button>
                      </div>
                    </td>
                  </tr>
                )}

                {filteredData.map((row, i) => {
                  const isEditingRow = isEditing === row && !isAdding;
                  return (
                    <tr key={i} className="hover:bg-gray-50 transition-colors">
                      {columns[activeTab].map(col => (
                        <td key={col.key} className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                          {isEditingRow ? (
                            <input
                              type={col.type}
                              value={editForm[col.key] || ''}
                              onChange={(e) => setEditForm({ ...editForm, [col.key]: e.target.value })}
                              className="w-full p-2 border border-indigo-200 rounded focus:ring-2 focus:ring-indigo-500 outline-none"
                            />
                          ) : (
                            col.key.includes('cgpa_min') 
                              ? `${row[col.key]} - ${row[col.label.split(' ')[0].toLowerCase() + '_cgpa_max']}`
                              : row[col.key]
                          )}
                        </td>
                      ))}
                      <td className="px-6 py-4 text-right">
                        {isEditingRow ? (
                          <div className="flex items-center justify-end gap-2">
                            <button onClick={() => handleSave(activeTab)} className="p-1.5 bg-emerald-100 text-emerald-700 rounded hover:bg-emerald-200"><Check className="w-4 h-4" /></button>
                            <button onClick={() => setIsEditing(null)} className="p-1.5 bg-gray-100 text-gray-700 rounded hover:bg-gray-200"><X className="w-4 h-4" /></button>
                          </div>
                        ) : (
                          <div className="flex items-center justify-end gap-3">
                            <button onClick={() => handleEdit(row)} className="text-gray-400 hover:text-indigo-600 transition-colors"><Edit2 className="w-4 h-4" /></button>
                            <button onClick={() => handleDelete(row, activeTab)} className="text-gray-400 hover:text-red-600 transition-colors"><Trash2 className="w-4 h-4" /></button>
                          </div>
                        )}
                      </td>
                    </tr>
                  );
                })}
                {filteredData.length === 0 && !isAdding && !loading && (
                   <tr>
                     <td colSpan={columns[activeTab].length + 1} className="px-6 py-8 text-center text-gray-500 italic">
                       No {activeTab.replace('_', ' ')} records found.
                     </td>
                   </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}