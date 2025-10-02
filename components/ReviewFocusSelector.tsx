import React from 'react';
import { Bug, ShieldAlert, Zap, Palette, Lightbulb } from 'lucide-react';

const FOCUS_OPTIONS = [
    { id: 'Bugs', label: 'Bugs', Icon: Bug },
    { id: 'Security', label: 'Security', Icon: ShieldAlert },
    { id: 'Performance', label: 'Performance', Icon: Zap },
    { id: 'Style', label: 'Style', Icon: Palette },
    { id: 'Suggestions', label: 'Suggestions', Icon: Lightbulb },
];

interface ReviewFocusSelectorProps {
    selectedFocuses: string[];
    onFocusChange: (focuses: string[]) => void;
}

export const ReviewFocusSelector: React.FC<ReviewFocusSelectorProps> = ({ selectedFocuses, onFocusChange }) => {

    const handleToggle = (focusId: string) => {
        const newSelection = selectedFocuses.includes(focusId)
            ? selectedFocuses.filter(item => item !== focusId)
            : [...selectedFocuses, focusId];
        onFocusChange(newSelection);
    };

    return (
        <div className="bg-black/30 p-4 rounded-lg border border-gray-700/50">
            <h3 className="text-sm font-semibold text-gray-400 mb-3 tracking-widest">FOCUS_MATRIX (OPTIONAL)</h3>
            <div className="flex flex-wrap gap-2">
                {FOCUS_OPTIONS.map(({ id, label, Icon }) => {
                    const isSelected = selectedFocuses.includes(id);
                    return (
                        <button
                            key={id}
                            onClick={() => handleToggle(id)}
                            className={`flex items-center gap-2 px-3 py-1.5 text-sm font-medium rounded-sm transition-all duration-200 border
                                ${isSelected
                                    ? 'bg-accent/20 border-accent text-accent'
                                    : 'bg-gray-800/50 border-gray-700 text-gray-400 hover:bg-gray-700 hover:border-gray-600'
                                }`}
                            aria-pressed={isSelected}
                        >
                            <Icon className="h-4 w-4" />
                            <span>{label}</span>
                        </button>
                    );
                })}
            </div>
             <p className="text-xs text-gray-500 mt-3">
                &gt; Select one or more areas. If none, a comprehensive review is performed.
            </p>
        </div>
    );
};