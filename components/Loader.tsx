
import React from 'react';

export const Loader: React.FC = () => (
    <div className="flex flex-col items-center justify-center gap-4 w-full max-w-md">
        <div className="flex items-center text-lg font-medium text-gray-400">
            <span>&gt; Analyzing Code</span>
            <span className="blinking-cursor"></span>
        </div>
        <div className="w-full bg-accent/10 h-1 mt-2 rounded-sm overflow-hidden">
            <div className="h-full bg-accent progress-bar"></div>
        </div>
    </div>
);