import React, { useRef, useState } from 'react';
import { UploadCloud, FileText, X, CheckCircle } from 'lucide-react';

interface FileUploaderProps {
  onFileChange: (file: File | null) => void;
  onReview: () => void;
  isLoading: boolean;
  fileName: string | undefined;
}

export const FileUploader: React.FC<FileUploaderProps> = ({ onFileChange, onReview, isLoading, fileName }) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploadSuccess, setUploadSuccess] = useState(false);

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0] ?? null;
    onFileChange(file);
    if (file) {
        setUploadSuccess(true);
        setTimeout(() => {
            setUploadSuccess(false);
        }, 2500); // Show message for 2.5 seconds
    }
  };
  
  const handleClearFile = () => {
      onFileChange(null);
      if(fileInputRef.current) {
          fileInputRef.current.value = "";
      }
  }

  return (
    <div className="bg-black/30 p-6 rounded-lg border border-gray-700/50 shadow-lg flex flex-col md:flex-row items-center gap-4">
      <div className="flex-grow w-full">
        <label htmlFor="file-upload" className="cursor-pointer">
          <div className="flex items-center justify-center w-full h-24 border-2 border-dashed border-gray-600 rounded-md hover:border-accent hover:text-accent transition-colors bg-black/20">
            {uploadSuccess ? (
                <div className="flex items-center gap-3 text-accent animate-fade-in-up">
                    <CheckCircle className="h-6 w-6" />
                    <span className="font-medium">Upload Successful!</span>
                </div>
            ) : fileName ? (
              <div className="flex items-center gap-3 text-gray-300">
                <FileText className="h-6 w-6 text-accent" />
                <span className="font-medium">{fileName}</span>
                 <button 
                   onClick={(e) => { e.preventDefault(); handleClearFile(); }} 
                   className="p-1 rounded-full hover:bg-gray-700 transition-colors"
                   aria-label="Remove file"
                 >
                   <X className="h-4 w-4" />
                 </button>
              </div>
            ) : (
              <div className="flex items-center gap-3 text-gray-500">
                <UploadCloud className="h-6 w-6" />
                <span className="font-medium">Click to upload a code file</span>
              </div>
            )}
          </div>
        </label>
        <input
          id="file-upload"
          type="file"
          ref={fileInputRef}
          className="hidden"
          onChange={handleFileSelect}
        />
      </div>
      <button
        onClick={onReview}
        disabled={isLoading || !fileName}
        className="w-full md:w-auto px-6 py-3 bg-accent text-black font-bold rounded-md shadow-md hover:bg-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-terminal-bg focus:ring-accent transition-all duration-200 disabled:bg-gray-800 disabled:cursor-not-allowed disabled:text-gray-500 disabled:border disabled:border-gray-700 flex items-center justify-center gap-2"
      >
        {isLoading ? 'ANALYZING...' : 'REVIEW_CODE'}
      </button>
    </div>
  );
};