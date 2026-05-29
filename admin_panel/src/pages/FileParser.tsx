import React, { useState, useEffect } from 'react';
import { supabaseAdmin as supabase } from '../lib/supabase';
import { Upload, FileType, CheckCircle, AlertCircle, Loader2, Trash2, FolderPen } from 'lucide-react';
import toast from 'react-hot-toast';
import type { StorageFile } from '../types';



export function FileParser() {
  const [file, setFile] = useState<File | null>(null);
  const [parseType, setParseType] = useState<string>('exam');
  const [status, setStatus] = useState<'idle' | 'parsing' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState<string>('');
  
  const [activeSemesters, setActiveSemesters] = useState<any[]>([]);
  const [selectedTrack, setSelectedTrack] = useState('tri_semester');
  const [semesterContext, setSemesterContext] = useState<'current' | 'next'>('current');
  const [customFileName, setCustomFileName] = useState('');

  const [uploadedFiles, setUploadedFiles] = useState<{ folder: string, files: StorageFile[] }[]>([]);
  const [loadingFiles, setLoadingFiles] = useState(false);

  useEffect(() => {
    fetchActiveSemesters();
    fetchAllUploadedFiles();
  }, []);

  const fetchAllUploadedFiles = async () => {
    setLoadingFiles(true);
    try {
      const folders = ['facultylist', 'calendar', 'examschedule', 'advisingschedule'];
      const results = [];
      
      for (const folder of folders) {
        const { data, error } = await supabase.storage.from('academic_documents').list(folder, {
          limit: 50,
          offset: 0,
          sortBy: { column: 'created_at', order: 'desc' },
        });
        
        if (!error && data) {
           // filter out the empty placeholder folders that supabase sometimes returns
           const validFiles = data.filter(f => f.name !== '.emptyFolderPlaceholder' && f.id);
           if (validFiles.length > 0) {
             results.push({ folder, files: validFiles });
           }
        }
      }
      setUploadedFiles(results);
    } catch (err) {
      console.error('Failed to fetch files:', err);
    } finally {
      setLoadingFiles(false);
    }
  };

  const handleDeleteFile = async (folder: string, fileName: string) => {
    if (!window.confirm(`Are you sure you want to delete ${fileName}?`)) return;
    
    try {
      const { error } = await supabase.storage.from('academic_documents').remove([`${folder}/${fileName}`]);
      if (error) throw error;
      
      // Remove from UI
      setUploadedFiles(prev => prev.map(group => ({
        ...group,
        files: group.files.filter(f => f.name !== fileName)
      })).filter(group => group.files.length > 0));
      
    } catch (err: any) {
      toast.error(`Failed to delete: ${err.message}`);
    }
  };

  const fetchActiveSemesters = async () => {
    try {
      const { data } = await supabase.from('active_semester').select('*');
      if (data) setActiveSemesters(data);
    } catch (err) {
      console.error('Failed to fetch active semesters', err);
    }
  };

  const getPrefixForType = (type: string) => {
    switch (type) {
      case 'exam': return 'Exam Schedule';
      case 'course': return 'Faculty List';
      case 'calendar': return 'Academic Calender';
      case 'advising': return 'Faculty Advising';
      default: return 'Document';
    }
  };

  useEffect(() => {
    const active = activeSemesters.find(s => s.track === selectedTrack);
    const code = active ? (semesterContext === 'current' ? active.current_semester_code : active.next_semester_code) : '';
    const semName = code ? code.replace(/([a-zA-Z]+)(\d+)/, '$1 $2') : '';
    const ext = parseType === 'advising' ? '.eml' : '.pdf';
    const prefix = getPrefixForType(parseType);
    
    // Handshake with Azure Function: Bi-semester files MUST contain PHRM, LAW, or LLB.
    // We'll use 'PHRM LLB' as a standard suffix to ensure correct routing for all Bi-track documents.
    const trackSuffix = selectedTrack === 'bi_semester' ? ' PHRM LLB' : '';
    
    if (semName) {
      setCustomFileName(`${prefix} ${semName}${trackSuffix}${ext}`);
    } else {
      setCustomFileName(`${prefix}${trackSuffix}${ext}`);
    }
  }, [parseType, activeSemesters, selectedTrack, semesterContext]);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {        
    if (e.target.files && e.target.files.length > 0) {
      setFile(e.target.files[0]);
    }
  };

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) {
      setMessage('Please select a file to upload.');
      setStatus('error');
      return;
    }
    
    const ext = parseType === 'advising' ? '.eml' : '.pdf';
    if (!customFileName.endsWith(ext)) {
      setMessage(`Filename must end with ${ext}`);
      setStatus('error');
      return;
    }

    try {
      setStatus('parsing');
      setMessage('Uploading file to storage...');

      // Determine the correct folder based on document type
let folderName = 'misc';
        if (parseType === 'exam') folderName = 'examschedule';
        else if (parseType === 'course') folderName = 'facultylist';
        else if (parseType === 'calendar') folderName = 'calendar';
        else if (parseType === 'advising') folderName = 'advisingschedule';

      // Avoid spaces/weird chars exactly or keep filename mostly untouched? 
      // The user requested to edit it, and the Azure parser depends on naming (e.g. Faculty List Spring 2026.pdf).
      const finalName = customFileName.trim();
      const filePath = `${folderName}/${finalName}`;

      // Upload the file to the 'academic_documents' bucket
      // The Supabase storage.objects trigger 'parse_faculty_on_upload' will automatically
      // call the Azure Function webhook to process this newly uploaded file!   
      const { error: uploadError } = await supabase.storage   
        .from('academic_documents')
        .upload(filePath, file, {
          cacheControl: '3600',
          upsert: true
        });

      if (uploadError) {
        throw new Error(`Upload failed: ${uploadError.message}`);
      }

      setStatus('success');
        setMessage(`File uploaded to ${folderName}/ successfully! The backend webhook is now parsing it automatically. Please check the Parsing Logs tab after 1-2 minutes for the update.`);
      fetchAllUploadedFiles();

    } catch (err: any) {
      setStatus('error');
      setMessage(err.message || 'Error uploading or parsing file');
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-700">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-black text-slate-900 dark:text-white tracking-tight flex items-center gap-3">
          <Upload className="w-8 h-8 text-indigo-600 dark:text-indigo-400" />
          File Parsing System
        </h1>
      </div>

      <div className="bg-white dark:bg-slate-800 rounded-3xl shadow-sm border border-slate-100 dark:border-white/5 overflow-hidden">
        <div className="p-8">
          <form onSubmit={handleUpload} className="space-y-8">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div>
                <label className="block text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-2 ml-1">
                  Academic Track (Tri/Bi)
                </label>
                <select
                  value={selectedTrack}
                  onChange={(e) => setSelectedTrack(e.target.value)}
                  className="w-full px-5 py-4 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl focus:bg-white dark:focus:bg-slate-800 focus:ring-4 focus:ring-indigo-500/10 outline-none transition-all font-black text-slate-900 dark:text-white appearance-none cursor-pointer"
                >
                  <option value="tri_semester" className="dark:bg-slate-900">Tri-Semester (Standard)</option>
                  <option value="bi_semester" className="dark:bg-slate-900">Bi-Semester (Pharmacy/Law)</option>
                </select>
              </div>

              <div>
                <label className="block text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-2 ml-1">
                  Target Semester
                </label>
                <select
                  value={semesterContext}
                  onChange={(e) => setSemesterContext(e.target.value as any)}
                  className="w-full px-5 py-4 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl focus:bg-white dark:focus:bg-slate-800 focus:ring-4 focus:ring-indigo-500/10 outline-none transition-all font-black text-slate-900 dark:text-white appearance-none cursor-pointer"
                >
                  <option value="current" className="dark:bg-slate-900">Current Semester</option>
                  <option value="next" className="dark:bg-slate-900">Upcoming / Next Semester</option>
                </select>
                <p className="mt-2 text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-tight ml-1">
                  Switch to "Upcoming" if you are uploading data for the next term.
                </p>
              </div>

              <div>
                <label className="block text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-2 ml-1">
                  Document Type
                </label>
                <select
                  value={parseType}
                  onChange={(e) => setParseType(e.target.value)}
                  className="w-full px-5 py-4 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl focus:bg-white dark:focus:bg-slate-800 focus:ring-4 focus:ring-indigo-500/10 outline-none transition-all font-black text-slate-900 dark:text-white appearance-none cursor-pointer"
                >
                  <option value="exam" className="dark:bg-slate-900">Exam Schedule</option>
                  <option value="course" className="dark:bg-slate-900">Course Catalog / Advising</option>     
                  <option value="calendar" className="dark:bg-slate-900">Academic Calendar</option>
                  <option value="advising" className="dark:bg-slate-900">Faculty Advising Routine</option>
                </select>
              </div>

              <div>
                <label className="block text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-2 ml-1">
                  Final Upload Filename
                </label>
                <input
                  type="text"
                  value={customFileName}
                  onChange={(e) => setCustomFileName(e.target.value)}
                  className="w-full px-5 py-4 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-white/10 rounded-2xl focus:bg-white dark:focus:bg-slate-800 focus:ring-4 focus:ring-indigo-500/10 outline-none transition-all font-black text-slate-900 dark:text-white placeholder:text-slate-300 dark:placeholder:text-slate-600"
                  placeholder={parseType === 'advising' ? "e.g., Faculty Advising Spring 2026.eml" : "e.g., Faculty List Spring 2026.pdf"}
                />
                <p className="mt-2 text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-tight ml-1">
                  Auto-populated based on context. Ends in {parseType === 'advising' ? '.eml' : '.pdf'}.
                </p>
              </div>
            </div>

            <div>
              <label className="block text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-3 ml-1">  
                Upload Binary File
              </label>
              <div className="mt-1 flex justify-center px-8 pt-8 pb-10 border-2 border-slate-200 dark:border-white/10 border-dashed rounded-3xl hover:border-indigo-400 dark:hover:border-indigo-500 transition-all bg-slate-50 dark:bg-slate-900/50 group">
                <div className="space-y-4 text-center">
                  <div className="w-16 h-16 bg-white dark:bg-slate-800 rounded-2xl shadow-sm border border-slate-100 dark:border-white/5 flex items-center justify-center mx-auto group-hover:scale-110 transition-transform">
                    <FileType className="h-8 w-8 text-indigo-500" />      
                  </div>
                  <div className="flex text-sm text-slate-600 dark:text-slate-400 justify-center">   
                    <label
                      htmlFor="file-upload"
                      className="relative cursor-pointer rounded-md font-black text-indigo-600 dark:text-indigo-400 hover:text-indigo-500 transition-colors focus-within:outline-none"
                    >
                      <span>Upload a file</span>
                      <input id="file-upload" name="file-upload" type="file" className="sr-only" accept={parseType === 'advising' ? '.eml' : '.pdf'} onChange={handleFileChange} />
                    </label>
                    <p className="pl-1">or drag and drop</p>
                  </div>
                  <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">
                    {file ? file.name : `${parseType === 'advising' ? 'EML' : 'PDF'} up to 10MB`}
                  </p>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end pt-4">
              <button
                type="submit"
                disabled={status === 'parsing'}
                className="w-full md:w-auto flex items-center justify-center gap-3 px-10 py-4 bg-indigo-600 text-white rounded-2xl hover:bg-indigo-700 disabled:opacity-50 transition-all shadow-lg shadow-indigo-100 dark:shadow-none font-black text-[10px] uppercase tracking-widest"
              >
                {status === 'parsing' ? (
                  <><Loader2 className="w-4 h-4 animate-spin" /> Processing Matrix...</>
                ) : (
                  <><Upload className="w-4 h-4" /> Execute Data Parse</>        
                )}
              </button>
            </div>
          </form>

          {status !== 'idle' && (
            <div className={`mt-8 p-6 rounded-2xl border flex items-start gap-4 animate-in slide-in-from-top-4 ${      
              status === 'error' ? 'bg-rose-50 dark:bg-rose-500/10 text-rose-800 dark:text-rose-400 border-rose-100 dark:border-rose-500/20' :
              status === 'success' ? 'bg-emerald-50 dark:bg-emerald-500/10 text-emerald-800 dark:text-emerald-400 border-emerald-100 dark:border-emerald-500/20' :
              'bg-indigo-50 dark:bg-indigo-500/10 text-indigo-800 dark:text-indigo-400 border-indigo-100 dark:border-indigo-500/20'
            }`}>
              <div className="mt-1">
                {status === 'error' && <AlertCircle className="w-6 h-6 flex-shrink-0" />}
                {status === 'success' && <CheckCircle className="w-6 h-6 flex-shrink-0" />}
                {status === 'parsing' && <Loader2 className="w-6 h-6 flex-shrink-0 animate-spin" />}
              </div>

              <div className="flex-1">
                <h3 className="font-black text-sm uppercase tracking-widest">
                  {status === 'error' ? 'Parsing Failed' :
                   status === 'success' ? 'Parse Successful' :
                   'Parsing Document...'}
                </h3>
                <p className="text-sm font-medium mt-1 leading-relaxed">{message}</p>
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="bg-white dark:bg-slate-800 rounded-3xl shadow-sm border border-slate-100 dark:border-white/5 overflow-hidden">
        <div className="px-8 py-6 border-b border-slate-100 dark:border-white/5 flex flex-col md:flex-row justify-between items-center gap-4 bg-slate-50/50 dark:bg-white/5">
          <h2 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-3 tracking-tight">
            <div className="p-2 bg-indigo-50 dark:bg-indigo-500/10 rounded-xl">
              <FolderPen className="w-5 h-5 text-indigo-500" />
            </div>
            Academic Repository
          </h2>
          <button
            onClick={fetchAllUploadedFiles}
            className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-white/10 rounded-xl hover:bg-slate-50 dark:hover:bg-white/5 text-[10px] font-black text-slate-500 dark:text-slate-400 uppercase tracking-widest transition-all shadow-sm"
          >
            <Loader2 className={`w-3.5 h-3.5 ${loadingFiles ? 'animate-spin' : ''}`} />
            Refresh Index
          </button>
        </div>
        
        <div className="p-0">
          {loadingFiles && uploadedFiles.length === 0 ? (
            <div className="p-12 text-center">
              <Loader2 className="w-10 h-10 animate-spin mx-auto mb-4 text-indigo-500" />
              <p className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Scanning bucket objects...</p>
            </div>
          ) : uploadedFiles.length === 0 ? (
            <div className="p-12 text-center text-slate-400 dark:text-slate-500 font-bold text-sm">
               The academic repository is currently empty.
            </div>
          ) : (
            <div className="divide-y divide-slate-100 dark:divide-white/5">
              {uploadedFiles.map((group) => (
                <div key={group.folder} className="p-8">
                  <h3 className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-6 flex items-center gap-3">
                    <span className="text-indigo-600 dark:text-indigo-400">/</span> {group.folder}
                    <span className="bg-slate-100 dark:bg-slate-900 text-slate-500 dark:text-slate-400 py-1 px-3 rounded-full text-[10px] font-black border border-slate-200 dark:border-white/10 shadow-sm">{group.files.length}</span>
                  </h3>
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                    {group.files.map(f => (
                      <div key={f.id} className="flex items-center justify-between p-5 rounded-2xl bg-white dark:bg-slate-900 border border-slate-100 dark:border-white/10 hover:border-indigo-200 dark:hover:border-indigo-500 transition-all group shadow-sm">
                        <div className="flex items-start gap-4 truncate pr-4">
                          <div className="p-3 bg-slate-50 dark:bg-slate-800 rounded-xl group-hover:bg-indigo-50 dark:group-hover:bg-indigo-500/10 transition-colors">
                            <FileType className="w-5 h-5 text-indigo-400 group-hover:text-indigo-600 transition-colors flex-shrink-0" />
                          </div>
                          <div className="truncate">
                            <p className="text-sm font-black text-slate-900 dark:text-white truncate group-hover:tracking-tight transition-all" title={f.name}>{f.name}</p>
                            <p className="text-[10px] font-bold text-slate-400 dark:text-slate-500 mt-1 uppercase tracking-widest">
                              {f.metadata ? `${(f.metadata.size / 1024).toFixed(1)} KB` : 'Unknown size'} • 
                              {new Date(f.created_at || Date.now()).toLocaleDateString()}
                            </p>
                          </div>
                        </div>
                        <button
                          onClick={() => handleDeleteFile(group.folder, f.name)}
                          className="opacity-0 group-hover:opacity-100 p-3 text-rose-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-500/10 rounded-2xl transition-all flex-shrink-0"
                          title="Purge Object"
                        >
                          <Trash2 className="w-5 h-5" />
                        </button>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
