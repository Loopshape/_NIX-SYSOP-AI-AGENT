import React, { useState, useEffect, useRef } from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { Edit, Save, X, Bold, Italic, Code as CodeIcon, Pilcrow, List, ListOrdered } from 'lucide-react';
import { type ReviewItem } from '../types';

interface CodePanelProps {
    code: string;
    fileName: string;
    onCodeChange: (newCode: string) => void;
    reviewItems: ReviewItem[];
}

const getLanguageFromFileName = (fileName: string): string => {
    const extension = fileName.split('.').pop()?.toLowerCase();
    switch (extension) {
        case 'js': return 'javascript';
        case 'jsx': return 'jsx';
        case 'ts': return 'typescript';
        case 'tsx': return 'tsx';
        case 'py': return 'python';
        case 'java': return 'java';
        case 'c': return 'c';
        case 'cpp': return 'cpp';
        case 'css': return 'css';
        case 'html': return 'html';
        case 'json': return 'json';
        case 'md': return 'markdown';
        case 'sh': return 'bash';
        default: return 'plaintext';
    }
};

export const CodePanel: React.FC<CodePanelProps> = ({ code, fileName, onCodeChange, reviewItems }) => {
    const language = getLanguageFromFileName(fileName);
    const [isEditing, setIsEditing] = useState(false);
    const [editedCode, setEditedCode] = useState(code);
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    const highlightedLines = React.useMemo(() => 
        new Set(reviewItems.map(item => item.line).filter((line): line is number => line !== null)),
    [reviewItems]);

    useEffect(() => {
        setEditedCode(code);
    }, [code]);

    const handleSave = () => {
        onCodeChange(editedCode);
        setIsEditing(false);
    };

    const handleCancel = () => {
        setEditedCode(code);
        setIsEditing(false);
    };
    
    const applyFormatting = (wrapperStart: string, wrapperEnd: string = wrapperStart) => {
        const textarea = textareaRef.current;
        if (!textarea) return;

        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const selectedText = editedCode.substring(start, end);
        
        const newText = `${editedCode.substring(0, start)}${wrapperStart}${selectedText}${wrapperEnd}${editedCode.substring(end)}`;
        
        setEditedCode(newText);

        setTimeout(() => {
            textarea.focus();
            textarea.setSelectionRange(start + wrapperStart.length, start + wrapperStart.length + selectedText.length);
        }, 0);
    };

    const applyListFormatting = (listChar: '*' | '1.') => {
        const textarea = textareaRef.current;
        if (!textarea) return;

        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const selectedText = editedCode.substring(start, end);

        let newText;
        let newSelectionStart = start;
        let newSelectionEnd = end;

        if (selectedText.length > 0) {
            // Format selected lines as a list
            const lines = selectedText.split('\n');
            let formattedLines;
            if (listChar === '1.') {
                 formattedLines = lines.map((line, index) => line.trim() === '' ? line : `${index + 1}. ${line}`);
            } else {
                 formattedLines = lines.map(line => line.trim() === '' ? line : `${listChar} ${line}`);
            }
            const formattedText = formattedLines.join('\n');
            newText = `${editedCode.substring(0, start)}${formattedText}${editedCode.substring(end)}`;
            newSelectionEnd = start + formattedText.length;
        } else {
            // Insert a new list item
            const prefix = listChar === '1.' ? '1. ' : '* ';
            newText = `${editedCode.substring(0, start)}${prefix}${editedCode.substring(end)}`;
            newSelectionStart = newSelectionEnd = start + prefix.length;
        }

        setEditedCode(newText);
        setTimeout(() => {
            textarea.focus();
            textarea.setSelectionRange(newSelectionStart, newSelectionEnd);
        }, 0);
    };
    
    const charCount = editedCode.length;
    const wordCount = editedCode.trim().split(/\s+/).filter(Boolean).length;

    const lineProps = (lineNumber: number): React.HTMLProps<HTMLElement> => {
        const style: React.CSSProperties = { display: 'block', width: '100%' };
        if (highlightedLines.has(lineNumber)) {
            style.backgroundColor = 'rgba(57, 255, 20, 0.1)';
            style.boxShadow = 'inset 3px 0px 0px 0px #39ff14';
        }
        return { style };
    };


    return (
        <div className="bg-black/30 rounded-lg border border-gray-700/50 overflow-hidden">
            <div className="flex justify-between items-center px-4 py-2 bg-black/20 border-b border-gray-700/50">
                <h3 className="text-sm font-semibold text-accent tracking-widest">SOURCE_CODE_CONTENT</h3>
                <div className="flex items-center gap-4">
                    {isEditing ? (
                        <>
                            <button onClick={handleSave} className="flex items-center gap-1.5 text-xs text-green-400 hover:text-white transition-colors font-bold">
                                <Save className="h-4 w-4" /> SAVE
                            </button>
                            <button onClick={handleCancel} className="flex items-center gap-1.5 text-xs text-red-400 hover:text-white transition-colors font-bold">
                                <X className="h-4 w-4" /> CANCEL
                            </button>
                        </>
                    ) : (
                        <button onClick={() => setIsEditing(true)} className="flex items-center gap-1.5 text-xs text-gray-400 hover:text-accent transition-colors font-bold">
                            <Edit className="h-4 w-4" /> EDIT_CODE
                        </button>
                    )}
                </div>
            </div>

            {isEditing && (
                <div className="flex items-center gap-2 px-4 py-1.5 bg-black/20 border-b border-gray-700/50">
                    <button onClick={() => applyFormatting('**')} title="Bold" className="p-1 text-gray-400 hover:text-accent transition-colors rounded-sm hover:bg-gray-700"><Bold className="h-4 w-4" /></button>
                    <button onClick={() => applyFormatting('*')} title="Italic" className="p-1 text-gray-400 hover:text-accent transition-colors rounded-sm hover:bg-gray-700"><Italic className="h-4 w-4" /></button>
                    <div className="w-px h-5 bg-gray-700 mx-1"></div>
                    <button onClick={() => applyFormatting('`')} title="Inline Code" className="p-1 text-gray-400 hover:text-accent transition-colors rounded-sm hover:bg-gray-700"><CodeIcon className="h-4 w-4" /></button>
                    <button onClick={() => applyFormatting('```\n', '\n```')} title="Code Block" className="p-1 text-gray-400 hover:text-accent transition-colors rounded-sm hover:bg-gray-700"><Pilcrow className="h-4 w-4" /></button>
                    <div className="w-px h-5 bg-gray-700 mx-1"></div>
                    <button onClick={() => applyListFormatting('*')} title="Bulleted List" className="p-1 text-gray-400 hover:text-accent transition-colors rounded-sm hover:bg-gray-700"><List className="h-4 w-4" /></button>
                    <button onClick={() => applyListFormatting('1.')} title="Numbered List" className="p-1 text-gray-400 hover:text-accent transition-colors rounded-sm hover:bg-gray-700"><ListOrdered className="h-4 w-4" /></button>
                </div>
            )}

            <div className="max-h-96 overflow-y-auto">
                {isEditing ? (
                    <textarea
                        ref={textareaRef}
                        value={editedCode}
                        onChange={(e) => setEditedCode(e.target.value)}
                        className="w-full min-h-96 p-4 bg-terminal-bg text-green-400 font-mono text-sm resize-none focus:outline-none focus:ring-1 focus:ring-accent/50 caret-accent"
                        spellCheck="false"
                    />
                ) : (
                    <SyntaxHighlighter
                        language={language}
                        style={vscDarkPlus}
                        customStyle={{ margin: 0, padding: '1rem', backgroundColor: 'transparent' }}
                        codeTagProps={{ style: { fontFamily: '"Roboto Mono", monospace', fontSize: '0.875rem' }}}
                        showLineNumbers
                        wrapLines={true}
                        lineProps={lineProps}
                    >
                        {code}
                    </SyntaxHighlighter>
                )}
            </div>

            {isEditing && (
                 <div className="px-4 py-1 bg-black/20 border-t border-gray-700/50 text-right text-xs text-gray-500 font-mono">
                    {charCount} Characters / {wordCount} Words
                </div>
            )}
        </div>
    );
};
