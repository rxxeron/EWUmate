export const GRADE_SCALE = {
    'A+': 4.00,
    'A': 3.75,
    'A-': 3.50,
    'B+': 3.25,
    'B': 3.00,
    'B-': 2.75,
    'C+': 2.50,
    'C': 2.25,
    'D': 2.00,
    'F': 0.00,
    // Non-GPA grades
    'S': 0, 'U': 0, 'W': 0, 'P': 0, 'I': 0, 'R': 0
};

export const getGradePoint = (grade) => GRADE_SCALE[grade] || 0.00;

export const isGPAGrade = (grade) => {
    return ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'F'].includes(grade);
};

export const calculateCGPA = (results) => {
    // 1. Group by Course Code to find Retakes
    // Logic: If same course code appears multiple times, the EARLIER ones are "R" (if not already?)
    // Actually, usually the BEST or LATEST counts. 
    // The prompt says: "if someone took the same course ID then result should show R for that specific course".
    // We will assume "Pre-existing/Older" attempts become R.
    
    // Sort by Semester (chronological) need a semester value/order.
    // For now assuming results have a 'semester' field like 'Spring2025'.
    // We need a helper to sort semesters.
    
    // Standard Semester Order: Spring < Summer < Fall
    const getSemOrder = (semId) => {
        const year = parseInt(semId.slice(-4));
        const sem = semId.slice(0, -4);
        let sVal = 0;
        if (sem === 'Spring') sVal = 1;
        if (sem === 'Summer') sVal = 2;
        if (sem === 'Fall') sVal = 3;
        return year * 10 + sVal;
    };

    // Sort results oldest to newest
    const sorted = [...results].sort((a, b) => getSemOrder(a.semesterId) - getSemOrder(b.semesterId));

    const courseMap = new Map(); // Code -> Array of attempts

    sorted.forEach(res => {
        if (!courseMap.has(res.courseCode)) {
            courseMap.set(res.courseCode, []);
        }
        courseMap.get(res.courseCode).push(res);
    });

    let totalPoints = 0;
    let totalCredits = 0;
    const processedResults = [];

    courseMap.forEach((attempts) => {
        // Mark all but the LAST attempt as 'R' (Retaken)
        // Unless the last attempt is 'W' or 'I'?
        // Simplify: The latest attempt stands using the prompt's requested visual.
        
        attempts.forEach((att, index) => {
            const isLast = index === attempts.length - 1;
            let finalGrade = att.grade;
            let displayGrade = att.grade;
            
            // If there's a later attempt, this one is R
            if (!isLast) {
                // If it was already completed, it's now R.
                // But the prompt says "result should show R". 
                // We'll virtually display it as R, but keep the original record intact?
                // Or maybe we treat it as R for calculation.
                // The image shows "R: Retaken=0".
                displayGrade = `${att.grade}(R)`; // e.g. "C(R)"
            }

            // Calculation
            const credits = parseFloat(att.credits) || 0;
            
            if (isLast && isGPAGrade(finalGrade)) {
                const gp = getGradePoint(finalGrade);
                totalPoints += (gp * credits);
                totalCredits += credits;
                processedResults.push({ ...att, calculated: true, displayGrade: finalGrade });
            } else if (!isLast) {
                 // It's a retake
                 processedResults.push({ ...att, calculated: false, displayGrade: 'R', originalGrade: finalGrade });
            } else {
                 // Non-GPA grade (S, W etc)
                 processedResults.push({ ...att, calculated: false, displayGrade: finalGrade });
            }
        });
    });

    // Re-sort for display (Newest first maybe?)
    processedResults.sort((a,b) => getSemOrder(b.semesterId) - getSemOrder(a.semesterId));

    const cgpa = totalCredits > 0 ? (totalPoints / totalCredits).toFixed(2) : "0.00";
    
    return {
        cgpa,
        totalCredits,
        processedResults
    };
};
