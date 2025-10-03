export type LineType = 'log' | 'prompt' | 'success' | 'error';

export interface StyledTerminalLine {
  text: string;
  type: LineType;
}

export enum ReviewCategory {
    BUG = 'BUG',
    VULNERABILITY = 'VULNERABILITY',
    PERFORMANCE = 'PERFORMANCE',
    STYLE = 'STYLE',
    SUGGESTION = 'SUGGESTION',
}
  
export interface ReviewItem {
    category: ReviewCategory;
    line: number | null;
    comment: string;
    suggestion?: string | null;
}

export enum ReviewItemStatus {
    PENDING = 'PENDING',
    ACCEPTED = 'ACCEPTED',
    REJECTED = 'REJECTED',
}

export interface ManagedReviewItem extends ReviewItem {
    id: string;
    status: ReviewItemStatus;
    userComments: string[];
}

