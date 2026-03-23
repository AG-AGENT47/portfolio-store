# Portfolio Store — CLAUDE.md

This repo is the single source of truth for Avyakt Garg's portfolio system.
It owns the Neon (PostgreSQL) schema, migrations, seed data, and pgvector knowledge base.
Both `portfolio-website` and `rag-chatbot` read from this database.

---

## Constraints

- **0-cost** — Neon free tier (10 GB, no auto-pause). No paid extensions or services.
- **Extensible** — new data types (certifications, publications, talks, etc.) should require only a new table + seed file, nothing else changes
- **Single source of truth** — all personal data lives here. Neither the website nor the chatbot hardcodes any personal info.

---

## Owner Info

```
Name:     Avyakt Garg
Email:    garg62@wisc.edu
Phone:    (608) 259-0543
LinkedIn: avyakt-garg
GitHub:   https://github.com/AG-AGENT47
Location: Madison, Wisconsin
```

---

## Education

```
1. M.S. in Computer Science
   University of Wisconsin–Madison
   Sep 2025 – May 2027
   GPA: 4.0/4.0

2. B.E. in Computer Science + M.Sc. in Biological Sciences (dual degree)
   Birla Institute of Technology and Science (BITS), Pilani
   Nov 2020 – May 2025
   GPA: 9.01/10

UW-Madison Courses (Fall 2025): CS 540 Intro to AI (A), CS 760 Machine Learning (A), CS 775 Computational Network Biology (A)
UW-Madison Courses (Spring 2026, in progress): CS 759 HPC for Applications in Engineering, CS 774 Data Exploration Cleaning & Integration

BITS Pilani CS Courses: Data Structures & Algorithms, Database Systems, OOP, Computer Networks,
Operating Systems, Microprocessors & Interfacing, Computer Architecture, Theory of Computation,
Design & Analysis of Algorithms, Discrete Structures, Logic in CS, Human Computer Interaction,
Digital Design, Compiler Construction, Principles of Programming Language, Probability & Statistics
BITS graduation: DISTINCTION, date of approval 30-JUN-2025
```

---

## Professional Experience

```
1. Uber — Software Intern
   Jul 2024 – Jun 2025
   - Developed an upcoming knowledge work marketplace for 5+ countries (data annotation + ML model training)
   - Implemented a rate-card system in Java SpringBoot using MVC; developed gRPC APIs for service integration
   - Created a Kafka-based notification engine with optimized cadence scheduling — improved customer retention funnel 3X
   - Built a debug tool with 7 automated checks for Uber AI Solutions — reduced developer dependency on recurring issues by 80%

2. University of Saskatchewan — Mitacs Research Intern
   May 2023 – Aug 2023
   - Collaborated with Prof. Jaswant Singh (biomedical sciences) on cattle health and reproduction data analysis
   - Automated daily cattle weighing via RFID-based data collection and analysis system — saved 3,000+ hrs/year
   - Revamped cattle management database (6,600+ entries) — 90% faster queries via genealogy links

3. Indian Institute of Technology, Ropar — Research Intern
   Jul 2022 – Sep 2022
   - Trained and evaluated ML models for cattle health monitoring using farm-based IoT sensor data
   - Analyzed 4,000+ data points for cattle behavior prediction: movement patterns and estrus detection

4. MapmyIndia — Software Intern
   May 2022 – Jul 2022
   - Built a web app for delivery executives using the traveling salesman algorithm for optimal trip routing
   - Integrated an interactive map API (HTML, CSS, JavaScript) with resizing and custom marker placement
```

---

## Projects

```
1. Graph Learning for Heart Disease Prediction (BMI/CS 775, UW-Madison)
   - UCI Heart Disease dataset (297 patients after cleaning); supervisors: Prof. Anthony Gitter + Prof. Sushmita Roy
   - Engineered Patient Similarity Networks (PSN) and Bipartite Patient-Attribute Graphs for non-i.i.d. clinical relations
   - Best model (PSN+GraphSAGE): 83.5% accuracy, 0.913 AUC-ROC, 0.827 F1, 0.860 Recall with Nested Cross-Validation
   - Integrated GNNExplainer for clinical transparency; deployed heart disease risk assessment web app via FastAPI + Streamlit

2. Patterning Protein Localisation in Endothelial Cells (Prof. Syamantak Majumder)
   - Automated cell segmentation software to detect protein localization in differently stained microscopy images
   - Used Otsu's thresholding with OpenCV — saved 6+ biologist hrs/study, improved nuclear detection 2X

3. Deep Learning Framework for ICP Prediction using OCT Scans (Prof. S. Raman)
   - Built a 3D ResNet-18 classifier for intracranial pressure prediction from OCT retinal scans
   - Preprocessed 512-frame videos to isolate key regions; fine-tuned architecture for safe patient threshold prediction

4. ML Techniques for Alzheimer's Disease Diagnosis (Prof. Bharat Richhariya)
   - Achieved 96.88% accuracy (100% sensitivity, 93.75% specificity) on 2,766 preprocessed 1.5T MRI scans from ADNI (CAT-12)
   - Used transfer learning to save compute and improve 3D ResNet-18 performance

5. T-9 Style Predictive Formula Entry System (BITS F364 HCI, April 2024, Dr. Mukesh Kumar Rohil)
   - T-9 phone keypad mapped to mathematical/Greek symbols for fast formula entry in text editors
   - Python Tkinter GUI with frequency-based prediction dictionary

6. GPU-Accelerated ANN Search with IVF-PQ Indexing (ME/CS/ECE 759 HPC, Spring 2026, in progress)
   - Implementing IVF-PQ (same algorithm as FAISS/Milvus/Pinecone) in CUDA C/C++
   - CUDA shared memory optimization, memory coalescing, warp divergence, Thrust/CUB, OpenMP
   - Benchmarking on SIFT1M; profiling with NVIDIA Nsight Compute on Euler HPC cluster (Slurm)
   - Due: 2026-05-05

7. E-commerce Management System (Coursework)
   - Built a MySQL-based e-commerce platform with product browsing and order placement
   - Designed a Python Tkinter GUI for order tracking, payment history, and feedback
```

---

## Achievements

```
- Globalink Research Scholarship — MITACS, Canada (Feb 2023): Selected from 30,000+ applicants
- Scholarship Awardee — AWaDH, Govt. of India (Apr 2022): For AI work in agriculture domain
- Gold Medalist — Delhi Public School R.K. Puram (May 2019): 9 years of academic excellence
- 86th Rank — JSTSE, Directorate of Education, Delhi (Feb 2017): Science merit scholarship
```

---

## Technical Skills

```
Languages:  Java, Python, C/C++, CUDA, SQL, HTML, JavaScript
Frameworks: SpringBoot, OpenCV, TensorFlow, PyTorch, Scikit-learn, GraphSAGE, Node2Vec, Pandas, NumPy, Thrust/CUB
Tools:      MVC, Kafka, Mockito, FastAPI, Streamlit, gRPC, REST, Docker, Git, Agile, JIRA, OpenMP, CMake
```

---

## Database Schema

All tables live in Neon (PostgreSQL). pgvector extension enabled via migration 002.

### Core Tables

```sql
-- Who you are (key/value: adding a field = adding one row, not ALTER TABLE)
personal_info (id UUID, key TEXT UNIQUE, value TEXT, created_at, updated_at)

-- Skills with categorization
skills (id UUID, name TEXT UNIQUE, category TEXT, proficiency TEXT,
        years_of_experience INT, display_order INT, created_at, updated_at)
-- category: 'language' | 'framework' | 'tool' | 'concept'
-- proficiency: 'beginner' | 'intermediate' | 'advanced' | 'expert'

-- Work history (bullets JSONB array for forward-compatible metadata)
experience (id UUID, company TEXT, role TEXT, location TEXT, start_date DATE,
            end_date DATE, is_current BOOL, description TEXT, bullets JSONB,
            display_order INT, created_at, updated_at)

-- Education (gpa_scale lets website display "9.01/10" vs "4.0/4.0" correctly)
education (id UUID, institution TEXT, degree TEXT, field TEXT, start_date DATE,
           end_date DATE, gpa NUMERIC, gpa_scale NUMERIC, courses TEXT[],
           display_order INT, created_at, updated_at)

-- Side projects and research
projects (id UUID, title TEXT UNIQUE, category TEXT, description TEXT,
          bullets JSONB, tech_stack TEXT[], github_url TEXT, live_url TEXT,
          collaborator TEXT, is_featured BOOL, display_order INT, created_at, updated_at)
-- category: 'research' | 'personal' | 'coursework' | 'professional'

-- Awards, scholarships, competitions
achievements (id UUID, title TEXT, organization TEXT, description TEXT,
              date DATE, category TEXT, display_order INT, created_at, updated_at)
-- category: 'scholarship' | 'award' | 'competition' | 'recognition'
```

### RAG + Metrics Tables

```sql
-- Chunked content for RAG retrieval
-- embedding VECTOR(512): Voyage AI voyage-3-lite dimensions (fixed at model selection)
knowledge_base (id UUID, content TEXT, source TEXT, source_type TEXT,
                metadata JSONB, embedding VECTOR(1024), created_at)
-- source_type: 'experience' | 'project' | 'education' | 'achievement' | 'skill' | 'personal'
-- IVFFlat cosine index: ORDER BY embedding <=> $query LIMIT 5

-- Chatbot interaction logs — feeds website live metrics
interactions (id UUID, question TEXT, answer TEXT, latency_ms INT,
              rating INT CHECK (1–5), created_at TIMESTAMPTZ)
```

### Extensibility Rule
To add a new data type (e.g. certifications, publications, talks):
1. Add a new migration file in `migrations/`
2. Add a seed file in `seeds/`
3. Add chunks to `scripts/embed.py` → re-run → re-run `seeds/knowledge_base.sql`
4. No other repo needs to change — the chatbot and website pick it up automatically

---

## Folder Structure

```
portfolio-store/
├── migrations/          # Numbered SQL migration files (001_init.sql, 002_add_x.sql...)
├── seeds/               # One seed file per table
│   ├── personal_info.sql
│   ├── skills.sql
│   ├── experience.sql
│   ├── education.sql
│   ├── projects.sql
│   ├── achievements.sql
│   └── knowledge_base.sql   # Pre-computed embeddings go here
├── scripts/
│   ├── embed.py         # Generates knowledge_base.sql via Voyage AI voyage-3-lite
│   └── requirements.txt
├── schema.sql           # Full schema snapshot (pg_dump, regenerated, not hand-edited)
└── CLAUDE.md
```
