import React, { useState } from 'react';
import { Header } from './components/Header';
import { FileUploader } from './components/FileUploader';
import { ReviewFocusSelector } from './components/ReviewFocusSelector';
import { ReviewPanel } from './components/ReviewPanel';
import { Loader } from './components/Loader';
import { ErrorAlert } from './components/ErrorAlert';
import { CodePanel } from './components/CodePanel';
import { type ReviewItem } from './types';
import { reviewCode } from './services/geminiService';

const App: React.FC = () => {
    const [file, setFile] = useState<File | null>(null);
    const [fileContent, setFileContent] = useState<string | null>(null);
    const [selectedFocuses, setSelectedFocuses] = useState<string[]>([]);
    const [reviewItems, setReviewItems] = useState<ReviewItem[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleFileChange = (selectedFile: File | null) => {
        setFile(selectedFile);
        setReviewItems([]);
        setError(null);
        setFileContent(null);

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
        setReviewItems([]);

        try {
            const items = await reviewCode(fileContent, selectedFocuses);
            setReviewItems(items);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'An unknown error occurred during review.');
        } finally {
            setIsLoading(false);
        }
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
                            reviewItems={reviewItems}
                        />
                    )}

                    {isLoading && (
                        <div className="flex justify-center p-8">
                            <Loader />
                        </div>
                    )}
                    
                    {reviewItems.length > 0 && <ReviewPanel items={reviewItems} />}
                </div>
            </main>
        </div>
    );
};

export default App;