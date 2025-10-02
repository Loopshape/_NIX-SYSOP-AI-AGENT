import React from 'react';
import { AlertTriangle, X } from 'lucide-react';

interface ErrorAlertProps {
  message: string;
  onClose: () => void;
}

export const ErrorAlert: React.FC<ErrorAlertProps> = ({ message, onClose }) => {
    return (
        <div className="bg-red-500/10 border border-red-500/50 text-red-400 px-4 py-3 rounded-lg relative flex items-start gap-3" role="alert">
            <AlertTriangle className="h-5 w-5 mt-0.5 flex-shrink-0" />
            <div className="flex-grow">
                <strong className="font-bold">ERROR: </strong>
                <span className="block sm:inline">{message}</span>
            </div>
            <button onClick={onClose} className="p-1 rounded-full hover:bg-red-500/20 transition-colors">
                <X className="h-5 w-5" />
            </button>
        </div>
    );
};