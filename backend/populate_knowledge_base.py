"""
Data Population Script for Offline Knowledge Base
Populates the knowledge base with initial content:
- App FAQs
- Common educational Q&A
- Syllabus content samples
"""

import sys
import os
from pathlib import Path

backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from tools.offline_knowledge_base import get_knowledge_base
from tools.syllabus_parser import get_syllabus_parser

def populate_app_faqs(kb):
    """Populate app help FAQs for offline chatbot"""

    faqs = [

        {
            "question": "How do I use this app?",
            "answer": "This is Rural Education app. You can access timetable, notes, e-books, and AI-powered study tools. Use the bottom navigation to switch between sections. Voice commands are also supported - just tap the microphone icon.",
            "category": "navigation",
            "keywords": "how to use, getting started, navigation"
        },
        {
            "question": "How do I view my timetable?",
            "answer": "Go to the Timetable section from the home screen. You can view daily schedules, add classes, and set reminders. Swipe left/right to change days.",
            "category": "timetable",
            "keywords": "timetable, schedule, classes"
        },
        {
            "question": "How do I scan and save notes?",
            "answer": "Tap on 'Notes' > 'Scan' > Take photo of your handwritten notes. The app will convert it to text using OCR. You can edit and save it for later.",
            "category": "notes",
            "keywords": "scan, notes, OCR, handwriting"
        },

        {
            "question": "Can I use this app offline?",
            "answer": "Yes! Most features work offline including notes, timetable, saved e-books, and basic study assistant. Some features like YouTube recommendations require internet.",
            "category": "offline",
            "keywords": "offline, no internet, without wifi"
        },
        {
            "question": "How does voice input work?",
            "answer": "Tap the microphone icon anywhere in the app. Speak your question or command in Hindi, English, or Punjabi. The app will understand and respond.",
            "category": "voice",
            "keywords": "voice, speak, microphone, audio"
        },
        {
            "question": "What is Photomath feature?",
            "answer": "Photomath lets you solve math problems by taking a photo. Point camera at the problem, tap capture, and get step-by-step solution. Works for algebra, geometry, and arithmetic.",
            "category": "photomath",
            "keywords": "math, solve, camera, calculator"
        },

        {
            "question": "How do I share notes using QR code?",
            "answer": "Open the note > Tap 'Share' > Select 'QR Code'. Your friend can scan this QR code to receive the note directly without internet.",
            "category": "sharing",
            "keywords": "QR code, share, send, transfer"
        },
        {
            "question": "How do I scan QR code to receive notes?",
            "answer": "Go to Notes > Tap 'Scan QR' > Point camera at the QR code. The note will be automatically received and saved.",
            "category": "sharing",
            "keywords": "receive, scan QR, get notes"
        },

        {
            "question": "Is my data safe?",
            "answer": "Yes, your data is encrypted and stored securely. We don't share your information with third parties. You can review our privacy policy in Settings > Privacy.",
            "category": "privacy",
            "keywords": "safety, secure, privacy, data protection"
        },
        {
            "question": "How do I change language?",
            "answer": "Go to Settings > Language. Select from English, Hindi, or Punjabi. The entire app will switch to your chosen language.",
            "category": "settings",
            "keywords": "language, hindi, punjabi, translate"
        },

        {
            "question": "What can the study assistant help me with?",
            "answer": "The study assistant can explain topics, solve problems, generate quizzes, create study plans, and answer doubts. Ask anything related to your syllabus.",
            "category": "study",
            "keywords": "AI, assistant, help, study, learn"
        },
        {
            "question": "Can I get video recommendations?",
            "answer": "Yes, when online, the app recommends educational YouTube videos based on your syllabus and topics you're studying.",
            "category": "videos",
            "keywords": "youtube, videos, recommendations, watch"
        },

        {
            "question": "App is running slow, what should I do?",
            "answer": "Try these steps: 1) Clear cache from Settings > Storage 2) Close other apps 3) Restart the app 4) Update to latest version. The app is optimized for low-end phones.",
            "category": "troubleshooting",
            "keywords": "slow, lag, performance, fix"
        },
        {
            "question": "Why can't I connect to internet?",
            "answer": "Most features work offline. For online features, check your WiFi/data connection. The app works even on 2G networks. If offline, a small indicator will show at the top.",
            "category": "troubleshooting",
            "keywords": "internet, connection, wifi, network"
        }
    ]

    print("📝 Populating app FAQs...")
    for faq in faqs:
        kb.add_app_faq(**faq)
        print(f"  ✓ Added: {faq['question'][:50]}...")

    print(f"✅ Added {len(faqs)} app FAQs\n")

def populate_educational_content(kb):
    """Populate general educational Q&A"""

    qa_pairs = [

        {
            "question": "What is photosynthesis?",
            "answer": "Photosynthesis is the process by which green plants make their own food using sunlight, water, and carbon dioxide. Chlorophyll in leaves absorbs sunlight to convert CO2 and H2O into glucose and oxygen. Formula: 6CO2 + 6H2O + Light → C6H12O6 + 6O2",
            "category": "education",
            "subject": "Science",
            "grade_level": "8-10",
            "keywords": "photosynthesis, plants, chlorophyll, biology"
        },
        {
            "question": "What is Newton's First Law of Motion?",
            "answer": "Newton's First Law states that an object at rest stays at rest, and an object in motion stays in motion with the same speed and direction, unless acted upon by an external force. This is also called the Law of Inertia.",
            "category": "education",
            "subject": "Physics",
            "grade_level": "8-10",
            "keywords": "newton, motion, inertia, physics, force"
        },
        {
            "question": "What is the water cycle?",
            "answer": "The water cycle is the continuous movement of water on Earth. It includes: Evaporation (water → vapor), Condensation (vapor → clouds), Precipitation (rain/snow), and Collection (water bodies). This cycle repeats continuously.",
            "category": "education",
            "subject": "Science",
            "grade_level": "6-8",
            "keywords": "water cycle, evaporation, rain, condensation"
        },

        {
            "question": "What is the Pythagorean theorem?",
            "answer": "The Pythagorean theorem states that in a right triangle, the square of the hypotenuse equals the sum of squares of the other two sides. Formula: a² + b² = c², where c is the hypotenuse. Example: If sides are 3 and 4, hypotenuse = √(9+16) = 5",
            "category": "education",
            "subject": "Mathematics",
            "grade_level": "8-10",
            "keywords": "pythagoras, triangle, geometry, theorem"
        },
        {
            "question": "How do you find the area of a circle?",
            "answer": "Area of circle = πr², where r is the radius. Example: If radius = 7 cm, Area = 22/7 × 7 × 7 = 154 cm². Remember: diameter = 2 × radius, so if you have diameter, divide by 2 first.",
            "category": "education",
            "subject": "Mathematics",
            "grade_level": "6-10",
            "keywords": "circle, area, radius, geometry, pi"
        },

        {
            "question": "What is democracy?",
            "answer": "Democracy is a form of government where power is vested in the people. Citizens elect representatives through voting. Key features: Free and fair elections, fundamental rights, rule of law, and equality for all citizens. India is the world's largest democracy.",
            "category": "education",
            "subject": "Social Science",
            "grade_level": "8-10",
            "keywords": "democracy, government, voting, politics, civics"
        },
        {
            "question": "What caused the Indian Independence Movement?",
            "answer": "India's independence movement was caused by British colonial exploitation, economic drain, discriminatory policies, and denial of rights. Key leaders: Mahatma Gandhi (non-violence), Jawaharlal Nehru, Subhas Chandra Bose. India gained independence on August 15, 1947.",
            "category": "education",
            "subject": "History",
            "grade_level": "8-10",
            "keywords": "independence, freedom, gandhi, british, india"
        },

        {
            "question": "What are the parts of speech in English?",
            "answer": "There are 8 parts of speech: 1) Noun (person/place/thing) 2) Pronoun (he/she/it) 3) Verb (action) 4) Adjective (describes noun) 5) Adverb (describes verb) 6) Preposition (in/on/at) 7) Conjunction (and/but/or) 8) Interjection (wow/ouch)",
            "category": "education",
            "subject": "English",
            "grade_level": "6-10",
            "keywords": "grammar, parts of speech, english, noun, verb"
        },

        {
            "question": "What is an atom?",
            "answer": "An atom is the smallest unit of matter. It consists of: 1) Nucleus (center) containing protons (+charge) and neutrons (no charge) 2) Electrons (-charge) orbiting the nucleus. Atoms combine to form molecules.",
            "category": "education",
            "subject": "Chemistry",
            "grade_level": "8-10",
            "keywords": "atom, molecule, proton, electron, chemistry"
        },
        {
            "question": "What is the periodic table?",
            "answer": "The periodic table organizes all chemical elements by atomic number, electron configuration, and properties. Elements in the same column (group) have similar properties. There are 118 known elements. Hydrogen is the simplest, with 1 proton.",
            "category": "education",
            "subject": "Chemistry",
            "grade_level": "8-10",
            "keywords": "periodic table, elements, chemistry, mendeleev"
        }
    ]

    print("📚 Populating educational Q&A...")
    for qa in qa_pairs:
        kb.add_knowledge(**qa)
        print(f"  ✓ Added: {qa['question'][:60]}...")

    print(f"✅ Added {len(qa_pairs)} educational Q&A pairs\n")

def populate_syllabus_content(kb):
    """Populate syllabus content samples"""

    syllabus_items = [

        {
            "subject": "Science",
            "grade_level": "10",
            "topic": "Chemical Reactions and Equations",
            "content": "Understanding chemical reactions, balancing equations, types of reactions (combination, decomposition, displacement, redox), and everyday chemical reactions.",
            "difficulty": "intermediate"
        },
        {
            "subject": "Science",
            "grade_level": "10",
            "topic": "Life Processes",
            "content": "Nutrition, respiration, transportation, excretion in plants and animals. Understanding how living organisms maintain life through various processes.",
            "difficulty": "intermediate"
        },
        {
            "subject": "Science",
            "grade_level": "10",
            "topic": "Electricity",
            "content": "Electric current, potential difference, Ohm's law, resistance, series and parallel circuits, heating effect of current, and electric power.",
            "difficulty": "advanced"
        },

        {
            "subject": "Mathematics",
            "grade_level": "10",
            "topic": "Real Numbers",
            "content": "Euclid's division lemma, HCF and LCM, rational and irrational numbers, decimal expansions, and fundamental theorem of arithmetic.",
            "difficulty": "beginner"
        },
        {
            "subject": "Mathematics",
            "grade_level": "10",
            "topic": "Polynomials",
            "content": "Polynomial expressions, zeroes of polynomial, relationship between zeroes and coefficients, division algorithm for polynomials.",
            "difficulty": "intermediate"
        },
        {
            "subject": "Mathematics",
            "grade_level": "10",
            "topic": "Quadratic Equations",
            "content": "Standard form, solutions by factorization, completing the square, quadratic formula, nature of roots, and applications.",
            "difficulty": "advanced"
        },

        {
            "subject": "Social Science",
            "grade_level": "9",
            "topic": "The French Revolution",
            "content": "Causes of French Revolution, events of 1789, Declaration of Rights, rise of Napoleon, legacy and impact on Europe and the world.",
            "difficulty": "intermediate"
        },
        {
            "subject": "Social Science",
            "grade_level": "9",
            "topic": "India: Size and Location",
            "content": "India's geographical position, neighbors, states and union territories, physical features, climate diversity, and strategic importance.",
            "difficulty": "beginner"
        }
    ]

    print("🗂️  Populating syllabus content...")
    for item in syllabus_items:
        kb.add_syllabus_content(**item)
        print(f"  ✓ Added: {item['subject']} - {item['topic'][:40]}...")

    print(f"✅ Added {len(syllabus_items)} syllabus items\n")

def populate_syllabus_parser():
    """Populate syllabus parser with structured syllabus"""
    parser = get_syllabus_parser()

    print("📖 Populating structured syllabus data...")

    science_10_syllabus = """
1. Chemical Reactions and Equations
   - Types of chemical reactions
   - Balancing chemical equations
   - Effects of oxidation in everyday life

2. Acids, Bases and Salts
   - Understanding pH scale
   - Properties of acids and bases
   - Common salt and its compounds

3. Metals and Non-metals
   - Physical and chemical properties
   - Reactivity series
   - Extraction of metals

4. Life Processes
   - Nutrition in plants and animals
   - Respiration
   - Transportation
   - Excretion

5. Control and Coordination
   - Nervous system
   - Hormones in animals
   - Plant hormones

6. Electricity
   - Electric current and circuit
   - Ohm's law
   - Resistance and factors affecting it
   - Heating effect of electric current

7. Light - Reflection and Refraction
   - Reflection by spherical mirrors
   - Refraction of light
   - Lens formula and magnification
    """

    topics = parser.parse_syllabus_text(science_10_syllabus, "Science", "10", "CBSE")
    print(f"  ✓ Parsed {len(topics)} topics for Class 10 Science")

    math_10_syllabus = """
1. Real Numbers
   - Euclid's division lemma
   - Fundamental theorem of arithmetic
   - Revisiting rational and irrational numbers

2. Polynomials
   - Geometrical meaning of zeroes
   - Relationship between zeroes and coefficients
   - Division algorithm for polynomials

3. Pair of Linear Equations in Two Variables
   - Algebraic methods of solving
   - Graphical method
   - Equations reducible to linear form

4. Quadratic Equations
   - Standard form
   - Solution by factorization
   - Solution by completing the square
   - Nature of roots

5. Arithmetic Progressions
   - Introduction to AP
   - nth term of an AP
   - Sum of first n terms

6. Triangles
   - Similar triangles
   - Criteria for similarity
   - Pythagoras theorem
    """

    topics = parser.parse_syllabus_text(math_10_syllabus, "Mathematics", "10", "CBSE")
    print(f"  ✓ Parsed {len(topics)} topics for Class 10 Mathematics")

    print("✅ Syllabus parsing complete\n")

def main():
    """Main population script"""
    print("=" * 60)
    print("🚀 POPULATING OFFLINE KNOWLEDGE BASE")
    print("=" * 60)
    print()

    kb = get_knowledge_base()

    populate_app_faqs(kb)
    populate_educational_content(kb)
    populate_syllabus_content(kb)
    populate_syllabus_parser()

    stats = kb.get_stats()
    print("=" * 60)
    print("📊 KNOWLEDGE BASE STATISTICS")
    print("=" * 60)
    print(f"Total Knowledge Entries: {stats['total_knowledge']}")
    print(f"Total App FAQs: {stats['total_faqs']}")
    print(f"Total Syllabus Content: {stats['total_syllabus']}")
    print(f"Cached Items: {stats['cached_items']}")
    print()

    if stats['by_category']:
        print("By Category:")
        for category, count in stats['by_category'].items():
            print(f"  - {category}: {count}")

    print()
    print("✅ Data population complete!")
    print("=" * 60)

    kb.close()

if __name__ == "__main__":
    main()
