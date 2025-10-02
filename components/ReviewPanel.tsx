import React from 'react';
import { type ReviewItem, ReviewCategory } from '../types';
import { marked } from 'marked';
import { Bug, ShieldAlert, Zap, Palette, Lightbulb } from 'lucide-react';

const categoryConfig = {
  [ReviewCategory.BUG]: {
    Icon: Bug,
    color: 'text-red-400',
    borderColor: 'border-red-400',
    title: 'CRITICAL_BUG',
  },
  [ReviewCategory.VULNERABILITY]: {
    Icon: ShieldAlert,
    color: 'text-yellow-400',
    borderColor: 'border-yellow-400',
    title: 'SECURITY_VULNERABILITY',
  },
  [ReviewCategory.PERFORMANCE]: {
    Icon: Zap,
    color: 'text-purple-400',
    borderColor: 'border-purple-400',
    title: 'PERFORMANCE_ISSUE',
  },
  [ReviewCategory.STYLE]: {
    Icon: Palette,
    color: 'text-blue-400',
    borderColor: 'border-blue-400',
    title: 'STYLE_GUIDE_VIOLATION',
  },
  [ReviewCategory.SUGGESTION]: {
    Icon: Lightbulb,
    color: 'text-green-400',
    borderColor: 'border-green-400',
    title: 'SUGGESTION',
  },
};

const ReviewItemCard: React.FC<{ item: ReviewItem; index: number }> = ({ item, index }) => {
    const config = categoryConfig[item.category];

    const createMarkup = (markdownText: string) => {
        const rawMarkup = marked.parse(markdownText, { breaks: true, gfm: true });
        return { __html: rawMarkup };
    };

    return (
        <div 
            className={`border-l-4 bg-black/20 border border-gray-800/50 rounded-r-md overflow-hidden ${config.borderColor} opacity-0 animate-fade-in-up`}
            style={{ animationDelay: `${index * 100}ms`}}
        >
            <div className="p-4 flex items-start gap-4">
                <div className={`mt-1 flex-shrink-0 ${config.color}`}>
                    <config.Icon className="h-5 w-5" />
                </div>
                <div className="flex-grow">
                    <div className="flex justify-between items-baseline">
                        <h3 className={`font-bold tracking-widest ${config.color}`}>{config.title}</h3>
                        {item.line !== null && (
                            <span className="text-xs font-mono bg-gray-700 text-gray-300 px-2 py-0.5 rounded-sm">
                                L:{item.line}
                            </span>
                        )}
                    </div>
                    <div 
                        className="prose prose-sm prose-invert mt-2 text-gray-300 max-w-none prose-p:text-gray-300 prose-code:text-accent/80 prose-code:bg-gray-800 prose-code:p-1 prose-code:rounded-sm prose-code:font-mono prose-pre:bg-gray-800 prose-pre:p-3 prose-pre:rounded-md"
                        dangerouslySetInnerHTML={createMarkup(item.comment)}
                    />
                </div>
            </div>
        </div>
    );
};

export const ReviewPanel: React.FC<{ items: ReviewItem[] }> = ({ items }) => {
  return (
    <div className="space-y-4">
        <h2 className="text-xl font-bold text-accent border-b border-accent/30 pb-2 tracking-widest">ANALYSIS_COMPLETE</h2>
        {items.map((item, index) => (
            <ReviewItemCard key={index} item={item} index={index}/>
        ))}
    </div>
  );
};