import '../models/college_model.dart';

class MockData {
  static final List<String> _photosSet1 = [
    'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&q=80&w=1000',
    'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&q=80&w=1000',
    'https://images.unsplash.com/photo-1498243691581-b145c3f54a5a?auto=format&fit=crop&q=80&w=1000',
    'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&q=80&w=1000',
    'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&q=80&w=1000',
  ];

  static Map<String, CategoryCutoff> _generateCutoffs(double base) {
    return {
      'General': CategoryCutoff(expected2026: base, round1: base + 2, round2: base, round3: base - 2, previousYear: base - 1),
      'OBC': CategoryCutoff(expected2026: base - 25, round1: base - 20, round2: base - 25, round3: base - 30, previousYear: base - 26),
      'SC': CategoryCutoff(expected2026: base - 60, round1: base - 55, round2: base - 60, round3: base - 65, previousYear: base - 62),
      'ST': CategoryCutoff(expected2026: base - 80, round1: base - 75, round2: base - 80, round3: base - 85, previousYear: base - 82),
      'EWS': CategoryCutoff(expected2026: base - 15, round1: base - 10, round2: base - 15, round3: base - 20, previousYear: base - 16),
      'PwD': CategoryCutoff(expected2026: base - 160, round1: base - 150, round2: base - 160, round3: base - 170, previousYear: base - 162),
      'CW': CategoryCutoff(expected2026: base - 130, round1: base - 120, round2: base - 130, round3: base - 140, previousYear: base - 132),
      'Kashmiri Migrant': CategoryCutoff(expected2026: base - 90, round1: base - 80, round2: base - 90, round3: base - 100, previousYear: base - 92),
    };
  }

  static List<CourseCutoff> _generateCourses(double baseScore, List<String> popularCourses) {
    List<CourseCutoff> courses = [];
    if (popularCourses.contains('BA(H)') || popularCourses.contains('Arts')) {
      courses.add(CourseCutoff(
        courseName: 'BA (Hons) Economics',
        courseCombination: ['Economics'],
        cutoffs: _generateCutoffs(baseScore),
      ));
      courses.add(CourseCutoff(
        courseName: 'BA (Hons) Political Science',
        courseCombination: ['Political Science'],
        cutoffs: _generateCutoffs(baseScore - 4),
      ));
    }
    if (popularCourses.contains('BCom(H)') || popularCourses.contains('Commerce') || popularCourses.contains('BCom')) {
      courses.add(CourseCutoff(
        courseName: 'BCom (Hons)',
        courseCombination: ['Commerce', 'Accountancy'],
        cutoffs: _generateCutoffs(baseScore + 3),
      ));
    }
    if (popularCourses.contains('BSc(H)') || popularCourses.contains('Science')) {
      courses.add(CourseCutoff(
        courseName: 'BSc (Hons) Computer Science',
        courseCombination: ['Computer Science', 'Mathematics'],
        cutoffs: _generateCutoffs(baseScore - 10),
      ));
    }
    if (popularCourses.contains('BMS')) {
      courses.add(CourseCutoff(
        courseName: 'BMS',
        courseCombination: ['Mathematics', 'General Test'],
        cutoffs: _generateCutoffs(baseScore + 2),
      ));
    }
    if (popularCourses.contains('Psychology')) {
      courses.add(CourseCutoff(
        courseName: 'BA (Hons) Psychology',
        courseCombination: ['Psychology'],
        cutoffs: _generateCutoffs(baseScore + 1),
      ));
    }
    if (popularCourses.contains('Journalism')) {
      courses.add(CourseCutoff(
        courseName: 'BA (Hons) Journalism',
        courseCombination: ['English', 'General Test'],
        cutoffs: _generateCutoffs(baseScore - 5),
      ));
    }
    
    if (courses.isEmpty) {
      courses.add(CourseCutoff(
        courseName: 'BA Program',
        courseCombination: ['Any 3 Domains'],
        cutoffs: _generateCutoffs(baseScore - 20),
      ));
    }
    return courses;
  }

  static final List<CollegeModel> colleges = [
    // NORTH CAMPUS
    CollegeModel(
      id: 'nc_1', name: 'Hindu College', campus: 'North Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/hindu.png', photos: _photosSet1, nirfRanking: 2,
      description: 'One of the most prestigious colleges in India, known for academic excellence.',
      courses: _generateCourses(795, ['BA(H)', 'BCom(H)', 'BSc(H)']),
    ),
    CollegeModel(
      id: 'nc_2', name: 'Miranda House', campus: 'North Campus', type: 'Government', gender: 'Women',
      logoUrl: 'assets/images/miranda.png', photos: _photosSet1, nirfRanking: 1,
      description: "Top ranked women's college offering exceptional science and arts programs.",
      courses: _generateCourses(792, ['BA(H)', 'BSc(H)']),
    ),
    CollegeModel(
      id: 'nc_3', name: "St. Stephen's College", campus: 'North Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/stephens.png', photos: _photosSet1, nirfRanking: 14,
      description: "Renowned for its BA(H) and BSc(H) programs.",
      courses: _generateCourses(796, ['BA(H)', 'BSc(H)']),
    ),
    CollegeModel(
      id: 'nc_4', name: 'Hansraj College', campus: 'North Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/hansraj.png', photos: _photosSet1, nirfRanking: 12,
      description: 'Known for its robust BCom(H) and Science programs.',
      courses: _generateCourses(790, ['BCom(H)', 'BSc(H)']),
    ),
    CollegeModel(
      id: 'nc_5', name: 'Kirori Mal College', campus: 'North Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/kmc.png', photos: _photosSet1, nirfRanking: 10,
      description: 'Famous for its vibrant arts and commerce culture.',
      courses: _generateCourses(785, ['BA(H)', 'BCom(H)']),
    ),
    CollegeModel(
      id: 'nc_6', name: 'Ramjas College', campus: 'North Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/ramjas.png', photos: _photosSet1, nirfRanking: 67,
      description: 'One of the oldest colleges with diverse programs.',
      courses: _generateCourses(782, ['BA(H)', 'BSc(H)']),
    ),
    CollegeModel(
      id: 'nc_7', name: 'Daulat Ram College', campus: 'North Campus', type: 'Government', gender: 'Women',
      logoUrl: 'assets/images/drc.png', photos: _photosSet1, nirfRanking: 28,
      description: "Premier women's college with comprehensive BA(H) and BSc(H) courses.",
      courses: _generateCourses(775, ['BA(H)', 'BSc(H)']),
    ),
    CollegeModel(
      id: 'nc_8', name: 'Sri Guru Tegh Bahadur Khalsa College', campus: 'North Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/sgtb.png', photos: _photosSet1, nirfRanking: 62,
      description: 'Strong focus on Commerce and Arts with excellent facilities.',
      courses: _generateCourses(778, ['Commerce', 'Arts']),
    ),
    CollegeModel(
      id: 'nc_9', name: 'Indraprastha College for Women', campus: 'North Campus', type: 'Government', gender: 'Women',
      logoUrl: 'assets/images/ip.png', photos: _photosSet1, nirfRanking: 97,
      description: "Oldest women's college, particularly noted for Psychology and Arts.",
      courses: _generateCourses(780, ['BA(H)', 'Psychology']),
    ),

    // SOUTH CAMPUS
    CollegeModel(
      id: 'sc_1', name: 'Lady Shri Ram College for Women', campus: 'South Campus', type: 'Government', gender: 'Women',
      logoUrl: 'assets/images/lsr.png', photos: _photosSet1, nirfRanking: 9,
      description: 'Eminent institution highly regarded for BA(H) and Journalism.',
      courses: _generateCourses(794, ['BA(H)', 'Journalism', 'Psychology']),
    ),
    CollegeModel(
      id: 'sc_2', name: 'Sri Venkateswara College', campus: 'South Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/venky.png', photos: _photosSet1, nirfRanking: 13,
      description: 'A top-tier South Campus college excelling in Science and Commerce.',
      courses: _generateCourses(788, ['BSc(H)', 'Commerce']),
    ),
    CollegeModel(
      id: 'sc_3', name: 'Jesus and Mary College', campus: 'South Campus', type: 'Government', gender: 'Women',
      logoUrl: 'assets/images/jmc.png', photos: _photosSet1, nirfRanking: 38,
      description: "Prominent women's college known for BA(H) and BCom programs.",
      courses: _generateCourses(785, ['BA(H)', 'BCom']),
    ),
    CollegeModel(
      id: 'sc_4', name: 'Gargi College', campus: 'South Campus', type: 'Government', gender: 'Women',
      logoUrl: 'assets/images/gargi.png', photos: _photosSet1, nirfRanking: 31,
      description: 'Recognized for excellent BA(H) and BSc(H) infrastructure.',
      courses: _generateCourses(780, ['BA(H)', 'BSc(H)']),
    ),
    CollegeModel(
      id: 'sc_5', name: 'Kamla Nehru College', campus: 'South Campus', type: 'Government', gender: 'Women',
      logoUrl: 'assets/images/knc.png', photos: _photosSet1, nirfRanking: 43,
      description: 'Highly sought after for Arts and Commerce.',
      courses: _generateCourses(775, ['Arts', 'Commerce']),
    ),
    CollegeModel(
      id: 'sc_6', name: 'Maitreyi College', campus: 'South Campus', type: 'Government', gender: 'Women',
      logoUrl: 'assets/images/maitreyi.png', photos: _photosSet1, nirfRanking: 36,
      description: 'Renowned for comprehensive BA(H) and BCom degrees.',
      courses: _generateCourses(770, ['BA(H)', 'BCom']),
    ),
    CollegeModel(
      id: 'sc_7', name: 'Atma Ram Sanatan Dharma College', campus: 'South Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/arsd.png', photos: _photosSet1, nirfRanking: 6,
      description: 'High-ranking college with rigorous BCom(H) and Science programs.',
      courses: _generateCourses(778, ['BCom(H)', 'BSc(H)']),
    ),
    CollegeModel(
      id: 'sc_8', name: 'Shaheed Bhagat Singh College', campus: 'South Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/sbsc.png', photos: _photosSet1, nirfRanking: 34,
      description: 'Widely reputed as a premier destination for Commerce.',
      courses: _generateCourses(780, ['Commerce']),
    ),
    CollegeModel(
      id: 'sc_9', name: 'College of Vocational Studies', campus: 'South Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/cvs.png', photos: _photosSet1, nirfRanking: 40,
      description: 'Specializes in BMS and Commerce programs.',
      courses: _generateCourses(772, ['BMS', 'Commerce']),
    ),

    // OFF CAMPUS
    CollegeModel(
      id: 'oc_1', name: 'Aryabhatta College', campus: 'Off Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/aryabhatta.png', photos: _photosSet1, nirfRanking: 30,
      description: 'Rapidly growing college focusing on BA(H) and BCom.',
      courses: _generateCourses(765, ['BA(H)', 'BCom']),
    ),
    CollegeModel(
      id: 'oc_2', name: 'Acharya Narendra Dev College', campus: 'Off Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/andc.png', photos: _photosSet1, nirfRanking: 21,
      description: 'Highly acclaimed for pure and applied Science programs.',
      courses: _generateCourses(760, ['Science']),
    ),
    CollegeModel(
      id: 'oc_3', name: 'Deen Dayal Upadhyaya College', campus: 'Off Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/dduc.png', photos: _photosSet1, nirfRanking: 24,
      description: 'Known for exceptional BMS and Commerce studies.',
      courses: _generateCourses(768, ['BMS', 'Commerce']),
    ),
    CollegeModel(
      id: 'oc_4', name: 'Delhi College of Arts and Commerce', campus: 'Off Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/dcac.png', photos: _photosSet1, nirfRanking: 84,
      description: 'A dedicated institution for Commerce and Arts.',
      courses: _generateCourses(770, ['Commerce', 'Arts']),
    ),
    CollegeModel(
      id: 'oc_5', name: 'Maharaja Agrasen College', campus: 'Off Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/mac.png', photos: _photosSet1, nirfRanking: 81,
      description: 'Quality education in Commerce and Arts domains.',
      courses: _generateCourses(762, ['Commerce', 'Arts']),
    ),
    CollegeModel(
      id: 'oc_6', name: 'Ramanujan College', campus: 'Off Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/ramanujan.png', photos: _photosSet1, nirfRanking: 58,
      description: 'Fast-rising college popular for its BCom programs.',
      courses: _generateCourses(765, ['BCom', 'BCom(H)']),
    ),
    CollegeModel(
      id: 'oc_7', name: 'Shivaji College', campus: 'Off Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/shivaji.png', photos: _photosSet1, nirfRanking: 70,
      description: 'Offers well-rounded BA(H) and BSc programs.',
      courses: _generateCourses(758, ['BA(H)', 'BSc(H)']),
    ),
    CollegeModel(
      id: 'oc_8', name: 'Zakir Husain Delhi College', campus: 'Off Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/zhdc.png', photos: _photosSet1, nirfRanking: 75,
      description: 'Historic college offering a wide array of Arts programs.',
      courses: _generateCourses(755, ['Arts']),
    ),
    CollegeModel(
      id: 'oc_9', name: 'Motilal Nehru College', campus: 'Off Campus', type: 'Government', gender: 'Co-ed',
      logoUrl: 'assets/images/mlnc.png', photos: _photosSet1, nirfRanking: 85,
      description: 'Well-established off-campus option for Commerce aspirants.',
      courses: _generateCourses(758, ['Commerce']),
    ),
  ];
}
