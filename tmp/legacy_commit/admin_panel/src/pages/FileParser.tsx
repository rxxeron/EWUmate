import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Upload, FileType, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';

export function FileParser() {
  const [file, setFile] = useState<File | null>(null);
  const [parseType, setParseType] = useState<string>('exam');
  const [status, setStatus] = useState<'idle' | 'parsing' | 'success' | 'error'>('idle');
  const [message, setMessage] = useState<string>('');
  const [results, setResults] = useState<any>(null);
  
  const [activeSemester, setActiveSemester] = useState('');
  const [customFileName, setCustomFileName] = useState('');

  useEffect(() => {
    fetchActiveSemester();
  }, []);

  const fetchActiveSemester = async () => {
    try {
      const { data } = await supabase
        .from('active_semester')
        .select('current_semester_code')
        .eq('track', 'tri_semester')
        .single();
        
      if (data && data.current_semester_code) {
        // e.g. "Spring2026" -> "Spring 2026"
        const formatted = data.current_semester_code.replace(/([a-zA-Z]+)(\d+)/, '$1 $2');
        setActiveSemester(formatted);
      }
    } catch (err) {
      console.error('Failed to fetch active semester', err);
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
    const ext = parseType === 'advising' ? '.eml' : '.pdf';
    if (activeSemester) {
      const prefix = getPrefixForType(parseType);
      setCustomFileName(`${prefix} ${activeSemester}${ext}`);
    } else {
      const prefix = getPrefixForType(parseType);
      setCustomFileName(`${prefix}${ext}`);
    }
  }, [parseType, activeSemester]);

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
      let folderName = '';
      if (parseType === 'exam') folderName = 'examschedule';
      else if (parseType === 'course') folderName = 'facultylist';
      else if (parseType === 'calendar') folderName = 'academiccalendar';       
      else if (parseType === 'advising') folderName = 'advisingschedule';       
      else folderName = 'misc';

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
      setMessage(`File uploaded to ${folderName}/ successfully! The backend webhook is now parsing it automatically.`);
      setResults({ filePath, bucket: 'academic_documents' });

    } catch (err: any) {
      setStatus('error');
      setMessage(err.message || 'Error uploading or parsing file');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold text-gray-900">File Parsing System</h1>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6">
          <form onSubmit={handleUpload} className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Document Type
                </label>
                <select
                  value={parseType}
                  onChange={(e) => setParseType(e.target.value)}
                  className="w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                >
                  <option value="exam">Exam Schedule</option>
                  <option value="course">Course Catalog / Advising</option>     
                  <option value="calendar">Academic Calendar</option>
                  <option value="advising">Faculty Advising Routine</option>
                </select>
                <p className="mt-1 text-xs text-gray-500">
                  Select the document type to auto-generate the filename prefix.
                </p>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Final Upload Filename
                </label>
                <input
                  type="text"
                  value={customFileName}
                  onChange={(e) => setCustomFileName(e.target.value)}
                  className="w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  placeholder={parseType === 'advising' ? "e.g., Faculty Advising Spring 2026.eml" : "e.g., Faculty List Spring 2026.pdf"}
                />
                <p className="mt-1 text-xs text-gray-500">
                  Auto-populated with the active semester. You can edit this if needed. Ensure it ends in {parseType === 'advising' ? '.eml' : '.pdf'}.
                </p>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">  
                Upload PDF File
              </label>
              <div className="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-xl hover:border-indigo-400 transition-colors bg-gray-50">
                <div className="space-y-1 text-center">
                  <FileType className="mx-auto h-12 w-12 text-gray-400" />      
                  <div className="flex text-sm text-gray-600 justify-center">   
                    <label
                      htmlFor="file-upload"
                      className="relative cursor-pointer rounded-md font-medium text-indigo-600 hover:text-indigo-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500"
                    >
                      <span>Upload a file</span>
                      <input id="file-upload" name="file-upload" type="file" className="sr-only" accept={parseType === 'advising' ? '.eml' : '.pdf'} onChange={handleFileChange} />
                    </label>
                    <p className="pl-1">or drag and drop</p>
                  </div>
                  <p className="text-xs text-gray-500">
                    {file ? file.name : `${parseType === 'advising' ? 'EML' : 'PDF'} up to 10MB`}
                  </p>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-end">
              <button
                type="submit"
                disabled={status === 'parsing'}
                className="flex items-center gap-2 px-6 py-2.5 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 transition-colors shadow-sm font-medium"
              >
                {status === 'parsing' ? (
                  <><Loader2 className="w-5 h-5 animate-spin" /> Processing...</>
                ) : (
                  <><Upload className="w-5 h-5" /> Execute Data Parse</>        
                )}
              </button>
            </div>
          </form>

          {status !== 'idle' && (
            <div className={`mt-6 p-4 rounded-lg flex items-start gap-3 ${      
              status === 'error' ? 'bg-red-50 text-red-800' :
              status === 'success' ? 'bg-emerald-50 text-emerald-800' :
              'bg-blue-50 text-blue-800'
            }`}>
              {status === 'error' && <AlertCircle className="w-5 h-5 mt-0.5 flex-shrink-0" />}
              {status === 'success' && <CheckCircle className="w-5 h-5 mt-0.5 flex-shrink-0" />}
              {status === 'parsing' && <Loader2 className="w-5 h-5 mt-0.5 flex-shrink-0 animate-spin" />}

              <div className="flex-1">
                <h3 className="font-semibold">
                  {status === 'error' ? 'Parsing Failed' :
                   status === 'success' ? 'Parse Successful' :
                   'Parsing Document...'}
                </h3>
                <p className="text-sm mt-1">{message}</p>

                {status === 'success' && results && (
                  <div className="mt-4">
                    <p className="text-sm font-medium mb-2">Server Response:</p>
                    <pre className="text-xs bg-white/50 p-3 rounded border border-emerald-100 overflow-x-auto">
                      {JSON.stringify(results, null, 2)}
                    </pre>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
