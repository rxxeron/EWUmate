/**
 * CampusMate Parser Utilities
 * Handles parsing of university specific codes and formats.
 */

const DAY_MAP = {
  'S': 'Sunday',
  'M': 'Monday',
  'T': 'Tuesday',
  'W': 'Wednesday',
  'R': 'Thursday',
  'F': 'Friday',
  'A': 'Saturday'
};

/**
 * Parses a day code string into an array of full day names.
 * Example: "SR" -> ["Sunday", "Thursday"]
 * Example: "MW" -> ["Monday", "Wednesday"]
 * @param {string} rawString - The day code string (e.g., "SR", "MW")
 * @returns {string[]} Array of day names
 */
export const parseDayCode = (rawString) => {
  if (!rawString) return [];
  
  const days = [];
  const chars = rawString.toUpperCase().split('');
  
  chars.forEach(char => {
    if (DAY_MAP[char]) {
      days.push(DAY_MAP[char]);
    }
  });
  
  return days;
};

/**
 * Determines the department based on the course code.
 * @param {string} courseCode - The course code (e.g., "ICE109", "MAT102")
 * @returns {string} The department name
 */
export const getDepartment = (courseCode) => {
  if (!courseCode) return 'Unknown Dept';
  
  const output = courseCode.toUpperCase();
  
  if (output.startsWith('CSE') || output.startsWith('ICE')) {
    return 'CSE Dept';
  } else if (output.startsWith('MAT') || output.startsWith('PHY') || output.startsWith('STA')) {
    return 'MPS Dept';
  } else if (output.startsWith('BUS') || output.startsWith('MKT')) {
    return 'BA Dept';
  } else if (output.startsWith('ENG')) {
    return 'English Dept';
  }
  
  return 'General Dept';
};
