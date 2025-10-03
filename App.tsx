import React, { useState } from 'react';
import { Header } from './components/Header';
import { FileUploader } from './components/FileUploader';
import { ReviewFocusSelector } from './components/ReviewFocusSelector';
import { ReviewPanel } from './components/ReviewPanel';
import { Loader } from './components/Loader';
import { ErrorAlert } from './components/ErrorAlert';
import { CodePanel } from './components/CodePanel';
import { type ManagedReviewItem, ReviewItemStatus, type ReviewItem } from './types';
import { reviewCode } from './services/geminiService';

const App: React.FC = () => {
    const [file, setFile] = useState<File | null>(null);
    const [fileContent, setFileContent] = useState<string | null>(null);
    const [selectedFocuses, setSelectedFocuses] = useState<string[]>([]);
    const [managedReviewItems, setManagedReviewItems] = useState<ManagedReviewItem[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [highlightedLine, setHighlightedLine] = useState<number | null>(null);

    const handleFileChange = (selectedFile: File | null) => {
        setFile(selectedFile);
        setManagedReviewItems([]);
        setError(null);
        setFileContent(null);
        setHighlightedLine(null);

        if (selectedFile) {
            const reader = new FileReader();
            reader.onload = (e) => {
                setFileContent(e.target?.result as string);
            };
            reader.onerror = () => {
                setError("Failed to read file.");
            };
            reader.readAsText(selectedFile);
        }
    };

    const handleCodeChange = (newCode: string) => {
        setFileContent(newCode);
    };

    const handleReview = async () => {
        if (!file || !fileContent) return;

        setIsLoading(true);
        setError(null);
        setManagedReviewItems([]);
        setHighlightedLine(null);

        try {
            const items = await reviewCode(fileContent, selectedFocuses);
            setManagedReviewItems(items.map((item) => ({
                ...item,
                id: crypto.randomUUID(),
                status: ReviewItemStatus.PENDING,
                userComments: [],
            })));
        } catch (err) {
            setError(err instanceof Error ? err.message : 'An unknown error occurred during review.');
        } finally {
            setIsLoading(false);
        }
    };

    const handleHighlightLine = (line: number | null) => {
        setHighlightedLine(line);
    };

    const handleUpdateReviewStatus = (itemId: string, status: ReviewItemStatus) => {
        setManagedReviewItems(prev =>
            prev.map(item => item.id === itemId ? { ...item, status } : item)
        );
    };

    const handleAcceptSuggestion = (itemId: string) => {
        const itemToAccept = managedReviewItems.find(i => i.id === itemId);
        if (!fileContent || !itemToAccept || !itemToAccept.suggestion || itemToAccept.line === null) {
            return;
        }

        const lines = fileContent.split('\n');
        const lineIndex = itemToAccept.line - 1;

        if (lineIndex >= 0 && lineIndex < lines.length) {
            const originalLine = lines[lineIndex];
            const leadingWhitespace = originalLine.match(/^\s*/)?.[0] ?? '';
            lines[lineIndex] = leadingWhitespace + itemToAccept.suggestion.trim();

            setFileContent(lines.join('\n'));
            handleUpdateReviewStatus(itemId, ReviewItemStatus.ACCEPTED);
            setHighlightedLine(null);
        }
    };

    const handleRejectSuggestion = (itemId: string) => {
        handleUpdateReviewStatus(itemId, ReviewItemStatus.REJECTED);
        setHighlightedLine(null);
    };

    const handleClearAllReviews = () => {
        setManagedReviewItems([]);
    };

    const handleAddComment = (itemId: string, comment: string) => {
        if (!comment.trim()) return;
        setManagedReviewItems(prev =>
            prev.map(item =>
                item.id === itemId
                    ? { ...item, userComments: [...item.userComments, comment] }
                    : item
            )
        );
    };


    return (
        <div className="min-h-screen">
            <Header />
            <main className="container mx-auto px-4 md:px-8 py-8">
                <div className="max-w-4xl mx-auto space-y-6">
                    <FileUploader
                        onFileChange={handleFileChange}
                        onReview={handleReview}
                        isLoading={isLoading}
                        fileName={file?.name}
                    />
                    <ReviewFocusSelector
                        selectedFocuses={selectedFocuses}
                        onFocusChange={setSelectedFocuses}
                    />

                    {error && <ErrorAlert message={error} onClose={() => setError(null)} />}

                    {fileContent && (
                        <CodePanel
                            code={fileContent}
                            fileName={file?.name ?? ''}
                            onCodeChange={handleCodeChange}
                            reviewItems={managedReviewItems}
                            highlightedLine={highlightedLine}
                        />
                    )}

                    {isLoading && (
                        <div className="flex justify-center p-8">
                            <Loader />
                        </div>
                    )}

                    {managedReviewItems.length > 0 &&
                        <ReviewPanel
                            items={managedReviewItems}
                            onHighlight={handleHighlightLine}
                            onAccept={handleAcceptSuggestion}
                            onReject={handleRejectSuggestion}
                            onClearAll={handleClearAllReviews}
                            onAddComment={handleAddComment}
                        />
                    }
                </div>
            </main>
        </div>
    );
};

export default App;
