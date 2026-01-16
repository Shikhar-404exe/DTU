"""
Offline PhotoMath Agent - Solves math problems from images without internet
Uses: OCR (Tesseract) + SymPy for symbolic math solving
"""

import re
import logging
from typing import Dict, List, Optional, Tuple
from PIL import Image
import numpy as np
import cv2
import os

try:
    import pytesseract
    from sympy import *
    from sympy.parsing.latex import parse_latex
    MATH_LIBS_AVAILABLE = True
except ImportError:
    MATH_LIBS_AVAILABLE = False
    logging.warning("Math solving libraries not installed. Run: pip install pytesseract sympy opencv-python Pillow numpy")

from .base_agent import BaseAgent, AgentMode, AgentCapability, AgentPriority

class OfflinePhotoMathAgent(BaseAgent):
    """
    Agent for solving math problems from camera images - FULLY OFFLINE
    Uses: OCR (Tesseract) + SymPy for symbolic math solving
    """

    def __init__(self):
        super().__init__(
            agent_id="offline_photomath",
            name="Offline PhotoMath Agent",
            description="Solves math problems from images using offline OCR and computer algebra",
            capabilities=[
                AgentCapability.IMAGE_PROCESSING,
                AgentCapability.CONTENT_GENERATION
            ],
            priority=AgentPriority.HIGH,
            default_mode=AgentMode.OFFLINE
        )

        if not MATH_LIBS_AVAILABLE:
            self.logger.error("Math solving libraries not available!")

        self.supported_operations = {
            'arithmetic': ['add', 'subtract', 'multiply', 'divide'],
            'algebra': ['solve', 'expand', 'factor', 'simplify'],
            'calculus': ['differentiate', 'integrate', 'limit'],
            'trigonometry': ['sin', 'cos', 'tan', 'sec', 'csc', 'cot'],
            'geometry': ['area', 'perimeter', 'volume'],
        }

    def can_handle(self, query: str, context: Dict = None) -> float:
        """Check if this agent can handle the request"""
        if context and context.get('has_image'):
            return 0.95

        query_lower = query.lower()
        math_keywords = ['solve', 'calculate', 'find', 'equation', 'math problem', 'photomath']

        if any(kw in query_lower for kw in math_keywords):
            return 0.7

        return 0.3

    def process_offline(self, query: str, context: Dict = None) -> Dict:
        """Process math problem from image - OFFLINE MODE"""
        context = context or {}
        image_path = context.get('image_path')

        if not image_path:
            return {
                'success': False,
                'error': 'No image provided for math problem solving'
            }

        if not MATH_LIBS_AVAILABLE:
            return {
                'success': False,
                'error': 'Math solving libraries not installed',
                'install_command': 'pip install pytesseract sympy opencv-python Pillow numpy'
            }

        processed_image = self._preprocess_image(image_path)

        extracted_text = self._extract_text_ocr(processed_image)

        if not extracted_text:
            return {
                'success': False,
                'error': 'Could not extract text from image',
                'suggestion': 'Ensure image is clear and well-lit'
            }

        parsed_expressions = self._parse_math_expressions(extracted_text)

        solutions = self._solve_math_problems(parsed_expressions)

        return {
            'success': True,
            'extracted_text': extracted_text,
            'parsed_expressions': parsed_expressions,
            'solutions': solutions,
            'mode': 'offline',
            'engine': 'tesseract_ocr + sympy'
        }

    def process_online(self, query: str, context: Dict = None) -> Dict:
        """Online mode - fallback to offline (we prefer offline for privacy)"""
        return self.process_offline(query, context)

    def _preprocess_image(self, image_path: str) -> np.ndarray:
        """Preprocess image for better OCR accuracy"""
        try:

            img = cv2.imread(image_path)

            if img is None:
                self.logger.error(f"Could not read image: {image_path}")
                return None

            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

            thresh = cv2.adaptiveThreshold(
                gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                cv2.THRESH_BINARY, 11, 2
            )

            denoised = cv2.fastNlMeansDenoising(thresh)

            processed = self._deskew(denoised)

            return processed

        except Exception as e:
            self.logger.error(f"Image preprocessing failed: {e}")

            try:
                return cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
            except:
                return None

    def _deskew(self, image: np.ndarray) -> np.ndarray:
        """Correct image rotation/skew"""
        try:
            coords = np.column_stack(np.where(image > 0))
            angle = cv2.minAreaRect(coords)[-1]

            if angle < -45:
                angle = -(90 + angle)
            else:
                angle = -angle

            (h, w) = image.shape[:2]
            center = (w // 2, h // 2)
            M = cv2.getRotationMatrix2D(center, angle, 1.0)
            rotated = cv2.warpAffine(
                image, M, (w, h),
                flags=cv2.INTER_CUBIC,
                borderMode=cv2.BORDER_REPLICATE
            )

            return rotated
        except:
            return image

    def _extract_text_ocr(self, image: np.ndarray) -> str:
        """Extract text from image using Tesseract OCR"""
        try:
            if image is None:
                return ""

            pil_image = Image.fromarray(image)

            custom_config = r'--oem 3 --psm 6'
            text = pytesseract.image_to_string(pil_image, config=custom_config)

            return text.strip()

        except Exception as e:
            self.logger.error(f"OCR extraction failed: {e}")
            return ""

    def _parse_math_expressions(self, text: str) -> List[Dict]:
        """Parse mathematical expressions from extracted text"""
        expressions = []

        patterns = [

            r'([a-z])\s*([+\-*/^])\s*(\d+)\s*=\s*(\d+)',

            r'(\d*)\s*([a-z])\^2\s*([+\-])\s*(\d*)\s*([a-z])\s*([+\-])\s*(\d+)\s*=\s*0',

            r'(\d+)\s*([+\-*/])\s*(\d+)\s*([+\-*/])\s*(\d+)',

            r'(\d+)\s*([+\-*/])\s*(\d+)',

            r'd/d([a-z])\s*\((.+)\)',

            r'∫\s*(.+)\s*d([a-z])',
        ]

        for pattern in patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                expressions.append({
                    'raw': match.group(0),
                    'groups': match.groups(),
                    'type': self._identify_problem_type(match.group(0))
                })

        if not expressions:
            cleaned = self._clean_expression(text)
            if cleaned:
                expressions.append({
                    'raw': cleaned,
                    'groups': (),
                    'type': 'general'
                })

        return expressions

    def _clean_expression(self, text: str) -> str:
        """Clean and normalize mathematical expression"""

        replacements = {
            'х': 'x',
            '×': '*',
            '÷': '/',
            '−': '-',
            '√': 'sqrt',
            '²': '^2',
            '³': '^3',
        }

        cleaned = text
        for old, new in replacements.items():
            cleaned = cleaned.replace(old, new)

        cleaned = re.sub(r'[^0-9a-zA-Z+\-*/^()=\s.]', '', cleaned)

        return cleaned.strip()

    def _identify_problem_type(self, expression: str) -> str:
        """Identify the type of math problem"""
        expr_lower = expression.lower()

        if 'd/dx' in expr_lower or 'differentiate' in expr_lower:
            return 'differentiation'
        elif '∫' in expr_lower or 'integrate' in expr_lower:
            return 'integration'
        elif '^2' in expr_lower or 'quadratic' in expr_lower:
            return 'quadratic'
        elif '=' in expr_lower:
            return 'equation'
        elif any(op in expr_lower for op in ['+', '-', '*', '/']):
            return 'arithmetic'
        else:
            return 'unknown'

    def _solve_math_problems(self, expressions: List[Dict]) -> List[Dict]:
        """Solve parsed mathematical expressions"""
        solutions = []

        for expr_data in expressions:
            try:
                problem_type = expr_data['type']
                raw_expr = expr_data['raw']

                if problem_type == 'equation':
                    solution = self._solve_equation(raw_expr)
                elif problem_type == 'quadratic':
                    solution = self._solve_quadratic(raw_expr)
                elif problem_type == 'differentiation':
                    solution = self._solve_derivative(raw_expr)
                elif problem_type == 'integration':
                    solution = self._solve_integral(raw_expr)
                elif problem_type == 'arithmetic':
                    solution = self._solve_arithmetic(raw_expr)
                else:
                    solution = self._solve_general(raw_expr)

                solutions.append({
                    'problem': raw_expr,
                    'type': problem_type,
                    'solution': solution,
                    'steps': self._generate_steps(problem_type, raw_expr, solution)
                })

            except Exception as e:
                self.logger.error(f"Failed to solve {expr_data['raw']}: {e}")
                solutions.append({
                    'problem': expr_data['raw'],
                    'type': expr_data['type'],
                    'error': str(e),
                    'suggestion': 'Check if expression is correctly formatted'
                })

        return solutions

    def _solve_equation(self, expression: str) -> Dict:
        """Solve algebraic equation"""

        if '=' not in expression:
            raise ValueError("Not an equation (missing =)")

        lhs, rhs = expression.split('=')

        variables = re.findall(r'[a-z]', expression.lower())
        if not variables:

            return {
                'left': str(sympify(lhs)),
                'right': str(sympify(rhs)),
                'equal': sympify(lhs) == sympify(rhs)
            }

        var = symbols(variables[0])
        equation = Eq(sympify(lhs), sympify(rhs))
        solution = solve(equation, var)

        return {
            'variable': str(var),
            'solution': [str(sol) for sol in solution],
            'decimal': [float(sol.evalf()) if sol.is_number else str(sol) for sol in solution]
        }

    def _solve_quadratic(self, expression: str) -> Dict:
        """Solve quadratic equation ax^2 + bx + c = 0"""
        x = symbols('x')

        lhs = expression.split('=')[0]
        equation = sympify(lhs.replace('^', '**'))

        solutions = solve(equation, x)

        return {
            'roots': [str(sol) for sol in solutions],
            'decimal_roots': [float(sol.evalf()) if sol.is_number else str(sol) for sol in solutions],
            'discriminant': self._calculate_discriminant(equation)
        }

    def _solve_derivative(self, expression: str) -> Dict:
        """Calculate derivative"""

        match = re.search(r'd/d([a-z])\s*\((.+)\)', expression)
        if not match:
            raise ValueError("Invalid derivative format")

        var_name = match.group(1)
        func = match.group(2)

        var = symbols(var_name)
        f = sympify(func.replace('^', '**'))

        derivative = diff(f, var)

        return {
            'function': str(f),
            'variable': var_name,
            'derivative': str(derivative),
            'simplified': str(simplify(derivative))
        }

    def _solve_integral(self, expression: str) -> Dict:
        """Calculate integral"""
        match = re.search(r'∫\s*(.+)\s*d([a-z])', expression)
        if not match:
            raise ValueError("Invalid integral format")

        func = match.group(1)
        var_name = match.group(2)

        var = symbols(var_name)
        f = sympify(func.replace('^', '**'))

        integral = integrate(f, var)

        return {
            'function': str(f),
            'variable': var_name,
            'integral': str(integral) + ' + C',
            'note': 'C is the constant of integration'
        }

    def _solve_arithmetic(self, expression: str) -> Dict:
        """Solve basic arithmetic"""
        result = sympify(expression)

        return {
            'expression': expression,
            'result': str(result),
            'decimal': float(result.evalf()) if result.is_number else str(result)
        }

    def _solve_general(self, expression: str) -> Dict:
        """General solver for unknown types"""
        try:
            result = sympify(expression.replace('^', '**'))
            simplified = simplify(result)

            return {
                'expression': expression,
                'simplified': str(simplified),
                'evaluated': str(result.evalf()) if result.is_number else None
            }
        except:
            return {'error': 'Could not parse expression'}

    def _calculate_discriminant(self, equation) -> Optional[float]:
        """Calculate discriminant for quadratic"""
        try:
            x = symbols('x')
            coeffs = Poly(equation, x).all_coeffs()
            if len(coeffs) == 3:
                a, b, c = coeffs
                return float((b**2 - 4*a*c).evalf())
        except:
            return None

    def _generate_steps(self, problem_type: str, problem: str, solution: Dict) -> List[str]:
        """Generate step-by-step solution"""
        steps = []

        if problem_type == 'equation':
            steps = [
                f"Given equation: {problem}",
                f"Isolate variable: {solution.get('variable', 'x')}",
                f"Solution: {solution.get('solution', [])}",
            ]
        elif problem_type == 'quadratic':
            steps = [
                f"Given: {problem}",
                "Use quadratic formula: x = (-b ± √(b²-4ac)) / 2a",
                f"Discriminant: {solution.get('discriminant', 'N/A')}",
                f"Roots: {solution.get('roots', [])}",
            ]
        elif problem_type == 'arithmetic':
            steps = [
                f"Calculate: {problem}",
                f"Result: {solution.get('result', '')}",
            ]
        elif problem_type == 'differentiation':
            steps = [
                f"Function: f({solution.get('variable', 'x')}) = {solution.get('function', '')}",
                "Apply differentiation rules",
                f"Derivative: {solution.get('derivative', '')}",
            ]
        elif problem_type == 'integration':
            steps = [
                f"Function: {solution.get('function', '')}",
                "Apply integration rules",
                f"Integral: {solution.get('integral', '')}",
            ]

        return steps
