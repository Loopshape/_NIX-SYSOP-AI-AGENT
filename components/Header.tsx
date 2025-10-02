import React from 'react';
import { Code } from 'lucide-react';

export const Header: React.FC = () => {
    return (
        <header className="bg-black/30 backdrop-blur-sm border-b border-accent/30 sticky top-0 z-10">
            <div className="container mx-auto px-4 md:px-8">
                <div className="flex items-center justify-between h-16">
                    <div className="flex items-center gap-3">
                        <Code className="h-7 w-7 text-accent" style={{ filter: 'drop-shadow(0 0 5px #39ff14)' }} />
                        <h1 className="text-xl font-bold text-white tracking-widest">
                            GEMINI_CODE_REVIEWER
                        </h1>
                    </div>
                </div>
            </div>
        </header>
    );
};