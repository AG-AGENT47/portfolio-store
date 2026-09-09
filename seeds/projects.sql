-- Seed: projects
-- Run: psql $NEON_DATABASE_URL -f seeds/projects.sql
-- is_featured = TRUE: appears on homepage. FALSE: full portfolio page only.
-- tech_stack TEXT[]: machine-readable tag list, rendered as pill badges on website.
-- github_url and live_url are NULL until repos are made public — update via re-seed.
-- ON CONFLICT (title) DO UPDATE: upsert — safe to re-run.

INSERT INTO projects (title, category, description, bullets, tech_stack, github_url, live_url, collaborator, is_featured, display_order) VALUES
(
    'Graph Learning for Heart Disease Prediction',
    'research',
    'Graduate research project (BMI/CS 775, UW-Madison) using graph neural networks to model non-i.i.d. clinical relationships for heart disease risk assessment on the UCI Heart Disease dataset.',
    '[
        "Engineered Patient Similarity Networks (PSN) and Bipartite Patient-Attribute Graphs on the UCI Heart Disease dataset (297 patients after cleaning) to capture complex, non-independent-and-identically-distributed clinical relations",
        "Developed GraphSAGE (Graph Sample and Aggregate — a graph neural network for inductive node embedding) and Node2Vec (node embedding via random walks) pipelines — best model (PSN+GraphSAGE) achieved 83.5% accuracy, 0.913 AUC-ROC, 0.827 F1, and 0.860 Recall with Nested Cross-Validation",
        "Integrated GNNExplainer (Graph Neural Network explainability tool) for clinical transparency; deployed heart disease risk assessment web application via FastAPI backend and Streamlit frontend"
    ]'::jsonb,
    ARRAY['Python', 'PyTorch', 'PyTorch Geometric', 'GraphSAGE', 'Node2Vec', 'FastAPI', 'Streamlit'],
    'https://github.com/AG-AGENT47/heart-disease-gnn',
    'https://heart-disease-gnn-veoy8p8y2h6z2ahnszpcnm.streamlit.app',
    'Prof. Anthony Gitter, Prof. Sushmita Roy',
    TRUE,
    1
),
(
    'Patterning Protein Localisation in Endothelial Cells',
    'research',
    'Automated microscopy image analysis pipeline for detecting protein localization patterns in differently-stained cell images.',
    '[
        "Automated cell segmentation software to detect protein localization in differently stained fluorescence microscopy images using computer vision techniques",
        "Used Otsu''s thresholding with OpenCV (computer vision library) — saved 6+ biologist hours per study and improved nuclear detection accuracy 2X"
    ]'::jsonb,
    ARRAY['Python', 'OpenCV', 'NumPy'],
    NULL,
    NULL,
    'Prof. Syamantak Majumder',
    TRUE,
    2
),
(
    'Deep Learning Framework for ICP Prediction using OCT Scans',
    'research',
    'Medical imaging deep learning model for predicting intracranial pressure from OCT retinal scans.',
    '[
        "Built a 3D ResNet-18 (3-dimensional Residual Neural Network) classifier for intracranial pressure (ICP) prediction from OCT (Optical Coherence Tomography) retinal scan videos",
        "Preprocessed 512-frame videos to isolate key anatomical regions; fine-tuned architecture for safe patient threshold prediction without ground-truth pressure measurements"
    ]'::jsonb,
    ARRAY['Python', 'PyTorch', '3D ResNet-18'],
    NULL,
    NULL,
    'Prof. S. Raman',
    FALSE,
    3
),
(
    'ML Techniques for Alzheimer''s Disease Diagnosis',
    'research',
    'Transfer learning approach to Alzheimer''s diagnosis from MRI scans using the ADNI dataset.',
    '[
        "Achieved 96.88% accuracy (100% sensitivity, 93.75% specificity) using ML models on 2,766 preprocessed 1.5T MRI brain scans from the ADNI (Alzheimer''s Disease Neuroimaging Initiative) dataset, processed via CAT-12 toolbox",
        "Applied transfer learning to leverage pretrained 3D ResNet-18 weights — reduced compute requirements while improving classification performance on the small medical imaging dataset"
    ]'::jsonb,
    ARRAY['Python', 'PyTorch', '3D ResNet-18', 'Scikit-learn'],
    NULL,
    NULL,
    'Prof. Bharat Richhariya',
    FALSE,
    4
),
(
    'T-9 Style Predictive Formula Entry System',
    'coursework',
    'HCI course project (BITS F364, April 2024) — a T-9 inspired predictive input tool for mathematical and scientific symbols, supervised by Dr. Mukesh Kumar Rohil.',
    '[
        "Built a predictive formula entry system that maps phone keypad numbers to mathematical and Greek symbols (e.g., key 1 → +, v, θ; key 6 → Σ, α, β) — inspired by T-9 predictive text algorithm",
        "Implemented frequency-based prediction dictionary in Python Tkinter: the most-used formulas automatically rise to the top; GUI shows all possible symbol combinations and live predictions on each keypress"
    ]'::jsonb,
    ARRAY['Python', 'Tkinter'],
    'https://github.com/AG-AGENT47/t9-formula-entry',
    NULL,
    'Dr. Mukesh Kumar Rohil',
    FALSE,
    5
),
(
    'GPU-Accelerated ANN Search with IVF-PQ Indexing',
    'coursework',
    'Graduate HPC project (ME/CS/ECE 759, Spring 2026) — implementing a GPU-accelerated approximate nearest neighbor search engine using IVF-PQ, the algorithm powering production vector databases like FAISS and Milvus.',
    '[
        "Implementing IVF-PQ (Inverted File Index with Product Quantization) algorithm in CUDA C/C++ — the same core algorithm used by production vector databases FAISS, Milvus, and Pinecone for billion-scale ANN search",
        "Applying GPU performance engineering: shared memory optimization for ADC distance kernels, memory coalescing for PQ code access, warp divergence management, Thrust/CUB sorting/scanning, and CUDA streams",
        "Benchmarking 5 optimization stages (CPU baseline → fully optimized GPU IVF-PQ) on SIFT1M dataset using NVIDIA Nsight Compute profiling on Euler HPC cluster with Slurm job scheduling"
    ]'::jsonb,
    ARRAY['CUDA', 'C++', 'OpenMP', 'Thrust', 'CUB', 'CMake'],
    NULL,
    NULL,
    NULL,
    FALSE,
    6
),
(
    'E-commerce Management System',
    'coursework',
    'Full-stack e-commerce platform with relational database backend and GUI frontend.',
    '[
        "Built a MySQL-based e-commerce platform supporting product browsing, order placement, and inventory management",
        "Designed a Python Tkinter GUI (desktop graphical user interface) for order tracking, payment history, and customer feedback workflows"
    ]'::jsonb,
    ARRAY['MySQL', 'Python', 'Tkinter'],
    'https://github.com/AG-AGENT47/ecommerce-management-system',
    NULL,
    NULL,
    FALSE,
    7
),
(
    'FlashCard Application',
    'coursework',
    'OOP coursework project (BITS Pilani) — a Java + JavaFX desktop flashcard study tool supporting multiple card types with a factory design pattern.',
    '[
        "Built a multi-type flashcard system supporting MCQ (Multiple Choice), True/False, Fill-in-the-Blank, and Definition card formats — each implemented as a distinct class extending a shared Card abstract base",
        "Applied the Factory design pattern via a CardGenerator class to decouple card creation from card type logic; structured data around User, Deck, and Card models with a Category classification layer",
        "Implemented comprehensive exception handling with a dedicated ExceptionHandling package; built JavaFX GUI controllers for interactive card rendering and study session management"
    ]'::jsonb,
    ARRAY['Java', 'JavaFX'],
    'https://github.com/AG-AGENT47/flashcard-application',
    NULL,
    NULL,
    FALSE,
    8
),
(
    'Mound Data Structure (MoundDSA)',
    'coursework',
    'DSA coursework project — C implementation of a Mound, an array-based probabilistic concurrent priority queue supporting lock-free parallel inserts and extractions.',
    '[
        "Implemented a Mound (array-based concurrent priority queue) in C — a probabilistic data structure that maintains a loose heap property, enabling lock-free concurrent insertions and extractMin operations without traditional mutex locking",
        "Built insert and extractMin operations on the Mound with a driver harness for correctness verification across concurrent access patterns"
    ]'::jsonb,
    ARRAY['C'],
    NULL,
    NULL,
    NULL,
    FALSE,
    9
),
(
    'Compiler Frontend — Lexer and Parser',
    'coursework',
    'Group compiler construction project (CS F363, BITS Pilani, 2024) — built a complete lexer and LL(1) predictive parser in C from scratch for a custom grammar, as part of a 6-person team.',
    '[
        "Built a DFA-based maximal munch lexer with twin buffer input handling, keyword lookup table (lexeme.txt), and a tokenInfo struct (token type, lexeme, line number) — successfully tokenized 6 test programs with error reporting for unknown patterns, invalid symbols, and oversized identifiers",
        "Implemented a full LL(1) predictive parser: automated FIRST/FOLLOW set computation (ComputeFirstandFollowSets()), 52-non-terminal × 57-terminal parse table construction, parse tree generation with parent/child/count node structure, and synch-based error recovery for token-not-in-FIRST and follow-set synchronization",
        "Designed and implemented supporting ADTs in C: SET ADT for FIRST/FOLLOW sets, Stack ADT for parsing, Parse Tree ADT, and file reader for grammar specification — built with Makefile; code compiled with zero errors and no segmentation faults across all test cases"
    ]'::jsonb,
    ARRAY['C', 'Makefile'],
    'https://github.com/AG-AGENT47/compiler-construction',
    NULL,
    'Aryaman Chauhan, Devansh, Arnav Gujarathi, Akshaj Dixit, Tanushi Garg',
    FALSE,
    10
)
ON CONFLICT (title) DO UPDATE
    SET description   = EXCLUDED.description,
        bullets       = EXCLUDED.bullets,
        tech_stack    = EXCLUDED.tech_stack,
        github_url    = EXCLUDED.github_url,
        live_url      = EXCLUDED.live_url,
        collaborator  = EXCLUDED.collaborator,
        is_featured   = EXCLUDED.is_featured,
        display_order = EXCLUDED.display_order,
        updated_at    = NOW();
