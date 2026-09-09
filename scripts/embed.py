#!/usr/bin/env python3
"""
embed.py — Generate seeds/knowledge_base.sql with Google Gemini embeddings.

Usage:
    export GEMINI_API_KEY=your_key_here
    python scripts/embed.py

Pre-requisite:
    Free Google AI Studio key (no card): https://aistudio.google.com/apikey
    No pip install needed — this script uses only the Python standard library.

Output:
    seeds/knowledge_base.sql  — committed to the repo so no API call is needed
    at runtime. The chatbot reads pre-computed vectors, never calls the embedding API.

Chunking strategy (the most impactful RAG tuning decision):
    Rule: one semantically complete thought = one chunk.
    - One chunk per experience bullet (not the whole job description)
    - One chunk per project bullet
    - One chunk per achievement
    - One chunk per skill-category group
    - One chunk per education entry + its courses
    - One chunk for the personal bio

    Why bullet-level, not job-level?
    If a recruiter asks "did you use Kafka?", you want to retrieve exactly the
    Kafka bullet — not the entire Uber job description. Smaller, focused chunks
    = more precise retrieval.

Context enrichment (critical for vocabulary mismatch):
    Raw:      "Created a Kafka-based notification engine"
    Enriched: "Created a Kafka-based notification engine (Kafka is a distributed
               event streaming and pub-sub messaging platform) with optimized
               cadence scheduling at Uber"
    This ensures queries like "distributed messaging", "pub-sub", or "event
    streaming" all retrieve the Kafka bullet.
"""

import json
import os
import sys

# ---------------------------------------------------------------------------
# Chunk definitions — Avyakt Garg's complete portfolio data
# Each chunk: {"content": str, "source": str, "source_type": str, "metadata": dict}
# ---------------------------------------------------------------------------
CHUNKS = [
    # -----------------------------------------------------------------------
    # EXPERIENCE: Uber — Summer 2026, Customer Obsession org (second internship)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Software Engineer Intern at Uber's Customer Obsession org in Sunnyvale, California "
            "(May 2026 - Jul 2026) — Avyakt's second Uber internship, after the Jul 2024 - Jun 2025 "
            "one on Uber AI Solutions. Architected a self-service configuration approval workflow "
            "end-to-end, eliminating code deploys to onboard new configuration types and replacing "
            "a manual email-based approval process with an audit trail and per-type RBAC "
            "(role-based access control) where the prior system had none."
        ),
        "source": "uber_2026_experience",
        "source_type": "experience",
        "metadata": {"company": "Uber", "role": "Software Engineer Intern", "start_date": "2026-05-11"},
    },
    {
        "content": (
            "Built a transactional draft-to-live promotion flow across 14 gRPC RPCs at Uber "
            "(Customer Obsession, Sunnyvale, Summer 2026), using pessimistic locking to eliminate "
            "concurrent write races when promoting configuration drafts to production."
        ),
        "source": "uber_2026_experience",
        "source_type": "experience",
        "metadata": {"company": "Uber", "role": "Software Engineer Intern", "start_date": "2026-05-11"},
    },

    # -----------------------------------------------------------------------
    # EXPERIENCE: UW-Madison Teaching Assistant (current)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Teaching Assistant at the University of Wisconsin-Madison (started Sep 2026, current) "
            "for the course Data Management for Data Science."
        ),
        "source": "uw_ta_experience",
        "source_type": "experience",
        "metadata": {"company": "University of Wisconsin-Madison", "role": "Teaching Assistant", "start_date": "2026-09-02"},
    },

    # -----------------------------------------------------------------------
    # EXPERIENCE: Uber — Jul 2024–Jun 2025 (first internship)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Developed an upcoming knowledge work marketplace for 5+ countries covering data annotation "
            "and ML model training workflows at Uber, Hyderabad (Jul 2024 – Jun 2025). "
            "A knowledge work marketplace is a platform that connects task requesters with skilled workers "
            "for structured cognitive tasks like annotating training data for AI models."
        ),
        "source": "uber_experience",
        "source_type": "experience",
        "metadata": {"company": "Uber", "role": "Software Engineer Intern", "start_date": "2024-07-01"},
    },
    {
        "content": (
            "Implemented a rate-card system in Java SpringBoot (a Java framework for building REST APIs and "
            "microservices) using MVC (Model-View-Controller) architecture; developed gRPC "
            "(Google Remote Procedure Call — a high-performance binary protocol for inter-service "
            "communication) APIs for cross-service integration at Uber, Hyderabad (Jul 2024 – Jun 2025)."
        ),
        "source": "uber_experience",
        "source_type": "experience",
        "metadata": {"company": "Uber", "role": "Software Engineer Intern", "start_date": "2024-07-01"},
    },
    {
        "content": (
            "Created a Kafka-based notification engine with optimized cadence scheduling — improved "
            "customer retention funnel 3X at Uber, Hyderabad (Jul 2024 – Jun 2025). "
            "Kafka is a distributed event streaming and pub-sub (publish-subscribe) messaging platform "
            "used for high-throughput, low-latency data pipelines between services."
        ),
        "source": "uber_experience",
        "source_type": "experience",
        "metadata": {"company": "Uber", "role": "Software Engineer Intern", "start_date": "2024-07-01"},
    },
    {
        "content": (
            "Built a debug tool with 7 automated checks for Uber AI Solutions — reduced developer "
            "dependency on recurring issues by 80% at Uber, Hyderabad (Jul 2024 – Jun 2025). "
            "The tool automated diagnosis of common failure modes, replacing manual investigation by engineers."
        ),
        "source": "uber_experience",
        "source_type": "experience",
        "metadata": {"company": "Uber", "role": "Software Engineer Intern", "start_date": "2024-07-01"},
    },

    # -----------------------------------------------------------------------
    # EXPERIENCE: University of Saskatchewan (Mitacs)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Collaborated with Prof. Jaswant Singh (biomedical sciences) on cattle health and reproduction "
            "data analysis at the University of Saskatchewan, Canada (May 2023 - Aug 2023). "
            "Mitacs Globalink Research Internship — fully funded, selected from 30,000+ applicants."
        ),
        "source": "saskatchewan_experience",
        "source_type": "experience",
        "metadata": {"company": "University of Saskatchewan", "role": "Mitacs Research Intern", "start_date": "2023-05-01"},
    },
    {
        "content": (
            "Automated daily cattle weighing via RFID-based data collection and analysis system — "
            "saved 3,000+ hours per year of manual labor at the University of Saskatchewan (May 2023 - Aug 2023). "
            "RFID (Radio Frequency Identification) is a wireless technology using radio waves to "
            "automatically identify and track tags attached to objects — here, ear tags on cattle."
        ),
        "source": "saskatchewan_experience",
        "source_type": "experience",
        "metadata": {"company": "University of Saskatchewan", "role": "Mitacs Research Intern", "start_date": "2023-05-01"},
    },
    {
        "content": (
            "Revamped cattle management database with 6,600+ entries — achieved 90% faster queries "
            "via optimized genealogy links and indexing at the University of Saskatchewan (May 2023 - Aug 2023). "
            "Optimizations included adding relational foreign-key links for pedigree traversal and "
            "creating composite indexes on frequently-filtered date and tag columns."
        ),
        "source": "saskatchewan_experience",
        "source_type": "experience",
        "metadata": {"company": "University of Saskatchewan", "role": "Mitacs Research Intern", "start_date": "2023-05-01"},
    },

    # -----------------------------------------------------------------------
    # EXPERIENCE: IIT Ropar
    # -----------------------------------------------------------------------
    {
        "content": (
            "Trained and evaluated ML models (machine learning classification algorithms) for cattle health "
            "monitoring using farm-based IoT sensor data at IIT Ropar (Jul 2022 - Sep 2022). "
            "IoT (Internet of Things) sensors collected accelerometer and temperature data from cattle "
            "to predict health events without manual observation."
        ),
        "source": "iit_ropar_experience",
        "source_type": "experience",
        "metadata": {"company": "Indian Institute of Technology, Ropar", "role": "Research Intern", "start_date": "2022-07-01"},
    },
    {
        "content": (
            "Analyzed 4,000+ data points for cattle behavior prediction including movement patterns and "
            "estrus (reproductive cycle) detection at IIT Ropar (Jul 2022 - Sep 2022). "
            "Applied supervised classification to identify behavioral signatures correlated with health events."
        ),
        "source": "iit_ropar_experience",
        "source_type": "experience",
        "metadata": {"company": "Indian Institute of Technology, Ropar", "role": "Research Intern", "start_date": "2022-07-01"},
    },

    # -----------------------------------------------------------------------
    # EXPERIENCE: MapmyIndia
    # -----------------------------------------------------------------------
    {
        "content": (
            "Built a web app for delivery executives using the Traveling Salesman Problem (TSP) algorithm "
            "for optimal multi-stop trip routing at MapmyIndia (May 2022 - Jul 2022). "
            "TSP is a classic combinatorial optimization problem — finding the shortest route through "
            "a set of locations — applied here to minimize delivery travel time."
        ),
        "source": "mapmyindia_experience",
        "source_type": "experience",
        "metadata": {"company": "MapmyIndia", "role": "Software Intern", "start_date": "2022-05-01"},
    },
    {
        "content": (
            "Integrated an interactive map API with dynamic resizing and custom marker placement "
            "features at MapmyIndia (May 2022 - Jul 2022). "
            "Built with HTML, CSS, and JavaScript — the frontend rendered live map tiles with "
            "clickable delivery waypoints and route overlays."
        ),
        "source": "mapmyindia_experience",
        "source_type": "experience",
        "metadata": {"company": "MapmyIndia", "role": "Software Intern", "start_date": "2022-05-01"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: Graph Learning for Heart Disease Prediction
    # -----------------------------------------------------------------------
    {
        "content": (
            "Engineered Patient Similarity Networks (PSN) and Bipartite Patient-Attribute Graphs on the "
            "UCI Heart Disease dataset (297 patients after cleaning) to capture non-i.i.d. "
            "(non-independent and identically distributed) clinical relations for heart disease prediction "
            "(Graph Learning for Heart Disease Prediction, BMI/CS 775 graduate project at UW-Madison, "
            "supervised by Prof. Anthony Gitter and Prof. Sushmita Roy). "
            "Graph-based models outperform standard classifiers when patient relationships matter."
        ),
        "source": "graph_learning_project",
        "source_type": "project",
        "metadata": {"project": "Graph Learning for Heart Disease Prediction", "category": "research", "github_url": "https://github.com/AG-AGENT47/heart-disease-gnn", "live_url": "https://heart-disease-gnn-veoy8p8y2h6z2ahnszpcnm.streamlit.app"},
    },
    {
        "content": (
            "Developed GraphSAGE (Graph Sample and Aggregate — a graph neural network that generates "
            "embeddings by sampling and aggregating features from a node's local neighborhood) and "
            "Node2Vec (learns node embeddings via biased random walks on the graph) pipelines — "
            "best model (PSN+GraphSAGE) achieved 83.5% accuracy, 0.913 AUC-ROC, 0.827 F1, and 0.860 Recall "
            "with Nested Cross-Validation (Graph Learning for Heart Disease Prediction, graduate project)."
        ),
        "source": "graph_learning_project",
        "source_type": "project",
        "metadata": {"project": "Graph Learning for Heart Disease Prediction", "category": "research"},
    },
    {
        "content": (
            "Integrated GNNExplainer (a model-agnostic explainability tool for graph neural networks "
            "that identifies which subgraph and node features drove a prediction) for clinical transparency; "
            "deployed heart disease risk assessment web app via FastAPI (Python web framework) and Streamlit "
            "(Python dashboard library) (Graph Learning for Heart Disease Prediction, graduate project)."
        ),
        "source": "graph_learning_project",
        "source_type": "project",
        "metadata": {"project": "Graph Learning for Heart Disease Prediction", "category": "research"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: Protein Localisation
    # -----------------------------------------------------------------------
    {
        "content": (
            "Automated cell segmentation software to detect protein localization patterns in differently "
            "stained fluorescence microscopy images using computer vision (Patterning Protein Localisation "
            "in Endothelial Cells, research project with Prof. Syamantak Majumder). "
            "Protein localization — where in a cell a protein concentrates — is a key indicator of "
            "cellular health and function in biomedical research."
        ),
        "source": "protein_localisation_project",
        "source_type": "project",
        "metadata": {"project": "Patterning Protein Localisation in Endothelial Cells", "category": "research"},
    },
    {
        "content": (
            "Used Otsu's thresholding (an automatic image binarization algorithm that finds the optimal "
            "intensity cutoff to separate foreground from background) with OpenCV — saved 6+ biologist "
            "hours per study and improved nuclear detection accuracy 2X "
            "(Patterning Protein Localisation in Endothelial Cells, research project)."
        ),
        "source": "protein_localisation_project",
        "source_type": "project",
        "metadata": {"project": "Patterning Protein Localisation in Endothelial Cells", "category": "research"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: ICP Prediction
    # -----------------------------------------------------------------------
    {
        "content": (
            "Built a 3D ResNet-18 (3-dimensional Residual Neural Network with 18 layers — a deep "
            "learning architecture for volumetric video data) classifier for intracranial pressure (ICP) "
            "prediction from OCT (Optical Coherence Tomography) retinal scan videos "
            "(Deep Learning Framework for ICP Prediction, research project with Prof. S. Raman)."
        ),
        "source": "icp_prediction_project",
        "source_type": "project",
        "metadata": {"project": "Deep Learning Framework for ICP Prediction using OCT Scans", "category": "research"},
    },
    {
        "content": (
            "Preprocessed 512-frame OCT retinal scan videos to isolate key anatomical regions; "
            "fine-tuned 3D ResNet-18 architecture for safe patient threshold prediction without requiring "
            "invasive ground-truth ICP measurements (Deep Learning Framework for ICP Prediction, "
            "research project with Prof. S. Raman)."
        ),
        "source": "icp_prediction_project",
        "source_type": "project",
        "metadata": {"project": "Deep Learning Framework for ICP Prediction using OCT Scans", "category": "research"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: Alzheimer's Diagnosis
    # -----------------------------------------------------------------------
    {
        "content": (
            "Achieved 96.88% accuracy (100% sensitivity, 93.75% specificity) using ML models on 2,766 "
            "preprocessed 1.5T MRI brain scans from the ADNI (Alzheimer's Disease Neuroimaging Initiative) "
            "dataset, processed via CAT-12 toolbox "
            "(ML Techniques for Alzheimer's Disease Diagnosis, research project with Prof. Bharat Richhariya)."
        ),
        "source": "alzheimers_project",
        "source_type": "project",
        "metadata": {"project": "ML Techniques for Alzheimer's Disease Diagnosis", "category": "research"},
    },
    {
        "content": (
            "Applied transfer learning (reusing weights pretrained on large datasets to improve performance "
            "on smaller target datasets) to leverage pretrained 3D ResNet-18 weights — reduced compute "
            "requirements while improving classification performance on the small medical imaging dataset "
            "(ML Techniques for Alzheimer's Disease Diagnosis, research project)."
        ),
        "source": "alzheimers_project",
        "source_type": "project",
        "metadata": {"project": "ML Techniques for Alzheimer's Disease Diagnosis", "category": "research"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: T-9 Predictive Formula Entry (HCI)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Built a T-9 style predictive formula entry system that maps phone keypad numbers to "
            "mathematical and Greek symbols (e.g., key 1 → +, v, θ; key 6 → Σ, α, β) for fast "
            "equation input in text editors (BITS F364 Human Computer Interaction course project, "
            "April 2024, Dr. Mukesh Kumar Rohil). "
            "T-9 (Text on 9 keys) is a predictive text input method originally used on phone keypads."
        ),
        "source": "hci_project",
        "source_type": "project",
        "metadata": {"project": "T-9 Style Predictive Formula Entry System", "category": "coursework"},
    },
    {
        "content": (
            "Implemented frequency-based prediction dictionary in Python Tkinter (GUI framework): "
            "the most-used mathematical formulas automatically rise to the top on continuous use; "
            "GUI shows all possible symbol combinations and live predictions on each keypress "
            "(HCI course project, BITS Pilani, April 2024)."
        ),
        "source": "hci_project",
        "source_type": "project",
        "metadata": {"project": "T-9 Style Predictive Formula Entry System", "category": "coursework"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: GPU-Accelerated Vector Search Engine (HPC CS 759)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Built a 5-stage GPU approximate-nearest-neighbor (ANN) search pipeline in CUDA and OpenMP "
            "implementing FAISS-style IVF-PQ (Inverted File Index with Product Quantization) — the same "
            "core algorithm behind FAISS, Milvus, and Pinecone for large-scale vector similarity search "
            "(GPU-Accelerated Vector Search Engine, ME/CS/ECE 759 High Performance Computing graduate "
            "project at UW-Madison). Achieved a 127.8x speedup over the CPU baseline. "
            "ANN search is the backbone of RAG pipelines, recommendation systems, and image retrieval."
        ),
        "source": "hpc_project",
        "source_type": "project",
        "metadata": {"project": "GPU-Accelerated Vector Search Engine", "category": "coursework"},
    },
    {
        "content": (
            "Designed a shared-memory-tiled CUDA kernel for the GPU-Accelerated Vector Search Engine "
            "that cut global-memory traffic 32x and raised query throughput 6x on 1 million vectors. "
            "Further cut query latency 1.47x and index build time 2.38x via shared-memory lookup-table "
            "caching, an OpenMP-parallel k-means for codebook training, and CUDA streams for CPU-GPU "
            "pipeline overlap (CS 759 HPC graduate project)."
        ),
        "source": "hpc_project",
        "source_type": "project",
        "metadata": {"project": "GPU-Accelerated Vector Search Engine", "category": "coursework"},
    },
    {
        "content": (
            "Benchmarked the GPU-Accelerated Vector Search Engine across 5 optimization stages "
            "(CPU baseline through fully optimized GPU IVF-PQ) on the SIFT1M dataset (1M vectors, "
            "128 dimensions), profiling with NVIDIA Nsight Compute on the Euler HPC cluster (Slurm). "
            "Tracked queries per second, Recall@k, and speedup at each stage (CS 759 HPC graduate project)."
        ),
        "source": "hpc_project",
        "source_type": "project",
        "metadata": {"project": "GPU-Accelerated Vector Search Engine", "category": "coursework"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: RAG-Powered Portfolio Chatbot (this system)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Built the RAG-Powered Portfolio Chatbot — the AI chat on this very portfolio site — as a "
            "3-repo Go system: portfolio-store (Neon PostgreSQL + pgvector), rag-chatbot (Go API on "
            "Render), and portfolio-website (Next.js on Vercel). It streams LLM responses over SSE and "
            "retrieves context with hybrid search: pgvector cosine similarity plus Postgres full-text "
            "search, merged by Reciprocal Rank Fusion, returning the top 5 chunks per query."
        ),
        "source": "portfolio_rag_project",
        "source_type": "project",
        "metadata": {"project": "RAG-Powered Portfolio Chatbot", "category": "personal", "live_url": "https://rag-chatbot-qge9.onrender.com"},
    },
    {
        "content": (
            "The RAG-Powered Portfolio Chatbot uses Google Gemini gemini-embedding-001 (768-dim) for "
            "query embeddings and a pluggable LLM layer (Groq openai/gpt-oss-120b by default, Gemini as "
            "fallback) with zero-code provider switching. It adds prompt-injection guardrails, query "
            "contextualization for pronoun resolution, and a topic filter that redirects off-topic "
            "questions using the minimum vector distance across retrieved chunks — no LLM call needed. "
            "Written by Avyakt as a portfolio project demonstrating full-stack AI infrastructure."
        ),
        "source": "portfolio_rag_project",
        "source_type": "project",
        "metadata": {"project": "RAG-Powered Portfolio Chatbot", "category": "personal"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: Compiler Frontend — Lexer and Parser (CS F363)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Built a DFA-based maximal munch lexer (lexical analyzer) with twin buffer input handling "
            "and a keyword lookup table for a custom programming language grammar "
            "(CS F363 Compiler Construction, BITS Pilani, group project 2024). "
            "A lexer tokenizes raw source code into a stream of typed tokens — the first phase of compilation. "
            "DFA maximal munch selects the longest possible valid token at each step."
        ),
        "source": "compiler_project",
        "source_type": "project",
        "metadata": {"project": "Compiler Frontend — Lexer and Parser", "category": "coursework"},
    },
    {
        "content": (
            "Implemented a full LL(1) predictive parser with automated FIRST/FOLLOW set computation "
            "(ComputeFirstandFollowSets()), a 52-non-terminal × 57-terminal parse table, parse tree "
            "generation with parent/child/count node structure, and synch-based error recovery "
            "(CS F363 Compiler Construction, BITS Pilani, 2024). "
            "LL(1) parsing is a top-down parsing strategy that reads input left-to-right using 1 token "
            "lookahead — the basis for many production compilers."
        ),
        "source": "compiler_project",
        "source_type": "project",
        "metadata": {"project": "Compiler Frontend — Lexer and Parser", "category": "coursework"},
    },
    {
        "content": (
            "Designed and implemented supporting ADTs in C: SET ADT for FIRST/FOLLOW sets, Stack ADT "
            "for parsing, Parse Tree ADT, and file reader for grammar specification. Built with Makefile; "
            "all 6 test programs successfully lexed/tokenized, 4 successfully parsed "
            "(CS F363 Compiler Construction, BITS Pilani, 2024). "
            "Team of 6: Aryaman Chauhan, Devansh, Arnav Gujarathi, Akshaj Dixit, Tanushi Garg, Avyakt Garg."
        ),
        "source": "compiler_project",
        "source_type": "project",
        "metadata": {"project": "Compiler Frontend — Lexer and Parser", "category": "coursework"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: E-commerce System
    # -----------------------------------------------------------------------
    {
        "content": (
            "Built a MySQL-based e-commerce platform supporting product browsing, order placement, "
            "and inventory management with a relational database backend (E-commerce Management System, "
            "coursework project)."
        ),
        "source": "ecommerce_project",
        "source_type": "project",
        "metadata": {"project": "E-commerce Management System", "category": "coursework"},
    },
    {
        "content": (
            "Designed a Python Tkinter GUI (desktop graphical user interface library built into Python) "
            "for order tracking, payment history, and customer feedback workflows "
            "(E-commerce Management System, coursework project)."
        ),
        "source": "ecommerce_project",
        "source_type": "project",
        "metadata": {"project": "E-commerce Management System", "category": "coursework"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: FlashCard Application (OOP coursework)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Built a multi-type flashcard study application in Java + JavaFX (Java's GUI framework) "
            "supporting four card formats: MCQ (Multiple Choice Question), True/False, "
            "Fill-in-the-Blank (FIB), and Definition — each implemented as a distinct subclass "
            "extending a shared abstract Card base class (FlashCard Application, OOP coursework at BITS Pilani)."
        ),
        "source": "flashcard_project",
        "source_type": "project",
        "metadata": {"project": "FlashCard Application", "category": "coursework"},
    },
    {
        "content": (
            "Applied the Factory design pattern via a CardGenerator class to decouple card creation "
            "logic from card type details; structured the data model around User, Deck, and Card objects "
            "with a Category classification layer. Included a comprehensive ExceptionHandling package "
            "and JavaFX GUI controllers for interactive study session management "
            "(FlashCard Application, OOP coursework at BITS Pilani)."
        ),
        "source": "flashcard_project",
        "source_type": "project",
        "metadata": {"project": "FlashCard Application", "category": "coursework"},
    },

    # -----------------------------------------------------------------------
    # PROJECTS: MoundDSA (DSA coursework)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Implemented a Mound data structure in C — an array-based probabilistic concurrent priority queue "
            "that maintains a loose heap property, enabling lock-free concurrent insert and extractMin "
            "operations without traditional mutex locking (MoundDSA, DSA coursework at BITS Pilani). "
            "A Mound is a research-grade concurrent data structure used in parallel computing contexts "
            "where multiple threads need priority-based task scheduling without contention bottlenecks."
        ),
        "source": "mounddsa_project",
        "source_type": "project",
        "metadata": {"project": "Mound Data Structure (MoundDSA)", "category": "coursework"},
    },
    {
        "content": (
            "Built insert and extractMin operations on the Mound with a driver harness for correctness "
            "verification across concurrent access patterns (MoundDSA, DSA coursework at BITS Pilani). "
            "The implementation uses C with low-level memory management — demonstrating understanding "
            "of pointer arithmetic, array-based tree representations, and concurrent data structure invariants."
        ),
        "source": "mounddsa_project",
        "source_type": "project",
        "metadata": {"project": "Mound Data Structure (MoundDSA)", "category": "coursework"},
    },

    # -----------------------------------------------------------------------
    # EDUCATION
    # -----------------------------------------------------------------------
    {
        "content": (
            "M.S. in Computer Science at University of Wisconsin-Madison (Sep 2025 - May 2027), GPA 4.0/4.0. "
            "Coursework: Intro to Artificial Intelligence (CS 540), Machine Learning (CS 760), "
            "Computational Network Biology (CS 775), High Performance Computing for Applications in "
            "Engineering (CS 759), Data Exploration Cleaning and Integration (CS 774), and currently "
            "AI Agents, Next-Generation Data Systems, and Learning-Based Methods for Computer Vision."
        ),
        "source": "uwmadison_education",
        "source_type": "education",
        "metadata": {"institution": "University of Wisconsin-Madison", "degree": "M.S. Computer Science"},
    },
    {
        "content": (
            "B.E. in Computer Science + M.Sc. in Biological Sciences (dual degree) at BITS Pilani "
            "(Birla Institute of Technology and Science, one of India's top engineering universities), "
            "Nov 2020 - Jun 2025, GPA 9.01/10, DISTINCTION. "
            "CS courses: Data Structures & Algorithms, Database Systems, Object-Oriented Programming, "
            "Computer Networks, Operating Systems, Microprocessors & Interfacing, Computer Architecture, "
            "Theory of Computation, Design & Analysis of Algorithms, Discrete Structures, "
            "Logic in Computer Science, Human Computer Interaction, Digital Design, "
            "Compiler Construction, Principles of Programming Language."
        ),
        "source": "bits_education",
        "source_type": "education",
        "metadata": {"institution": "BITS Pilani", "degree": "B.E. + M.Sc. Dual Degree"},
    },

    # -----------------------------------------------------------------------
    # ACHIEVEMENTS
    # -----------------------------------------------------------------------
    {
        "content": (
            "Awarded the MITACS Globalink Research Scholarship (Feb 2023) — selected from 30,000+ "
            "applicants worldwide for a fully-funded research internship at the University of "
            "Saskatchewan, Canada. MITACS Globalink is one of the most competitive undergraduate "
            "research fellowships in Canada."
        ),
        "source": "mitacs_achievement",
        "source_type": "achievement",
        "metadata": {"organization": "MITACS, Canada", "year": 2023},
    },
    {
        "content": (
            "Awarded AWaDH Scholarship (Apr 2022) by the Agriculture and Water Technology Development "
            "Hub (AWaDH) under the Government of India for research contributions in AI applications "
            "for the agriculture domain."
        ),
        "source": "awadh_achievement",
        "source_type": "achievement",
        "metadata": {"organization": "AWaDH, Government of India", "year": 2022},
    },
    {
        "content": (
            "Gold Medalist at Delhi Public School R.K. Puram (May 2019) — awarded for 9 consecutive "
            "years of academic excellence."
        ),
        "source": "gold_medal_achievement",
        "source_type": "achievement",
        "metadata": {"organization": "Delhi Public School R.K. Puram", "year": 2019},
    },
    {
        "content": (
            "Ranked 86th in the Junior Science Talent Search Examination (JSTSE, Feb 2017) — a "
            "state-level science merit scholarship examination conducted by the Directorate of "
            "Education, Government of NCT of Delhi."
        ),
        "source": "jstse_achievement",
        "source_type": "achievement",
        "metadata": {"organization": "Directorate of Education, Delhi", "year": 2017},
    },

    # -----------------------------------------------------------------------
    # SKILLS (one chunk per category)
    # -----------------------------------------------------------------------
    {
        "content": (
            "Programming Languages: Java (expert, 3 years — production use at Uber with SpringBoot), "
            "Python (expert, 4 years — ML research and backend APIs), "
            "Go (advanced — built the rag-chatbot service and Uber Customer Obsession internship work), "
            "C/C++ (advanced, 3 years — systems programming coursework), "
            "CUDA (intermediate — GPU kernels), "
            "SQL (intermediate, 3 years — database design and querying), "
            "HTML (intermediate), JavaScript (intermediate), "
            "LaTeX (intermediate, 3 years — used for academic research reports and coursework documentation)."
        ),
        "source": "language_skills",
        "source_type": "skill",
        "metadata": {"category": "language"},
    },
    {
        "content": (
            "Frameworks and Libraries: SpringBoot (advanced — Java framework for microservices and REST APIs), "
            "GORM (intermediate — Go ORM), Protobuf (advanced — Protocol Buffers for gRPC schemas), "
            "TensorFlow (advanced — deep learning), PyTorch (advanced — deep learning and research), "
            "PyTorch Geometric (intermediate — graph neural network library, used for GraphSAGE/Node2Vec), "
            "Scikit-learn (advanced — classical ML), OpenCV (advanced — computer vision), "
            "GraphSAGE (advanced — graph neural networks), Node2Vec (advanced — graph embeddings), "
            "JavaFX (intermediate — Java GUI framework, used for FlashCard desktop application), "
            "Pandas (expert — data manipulation), NumPy (expert — numerical computing)."
        ),
        "source": "framework_skills",
        "source_type": "skill",
        "metadata": {"category": "framework"},
    },
    {
        "content": (
            "Tools and Platforms: Kafka (advanced — distributed event streaming, used at Uber), "
            "gRPC (advanced — RPC framework, used at Uber), REST (advanced — API design), "
            "FastAPI (advanced — Python web framework), Docker (intermediate — containerization), "
            "Git (expert — version control), MVC (advanced — architectural pattern), "
            "Claude Code and agentic development (advanced — AI-assisted engineering workflows), "
            "microservices and monorepo architecture (advanced — service and repo design), "
            "Mockito (intermediate — Java unit testing and mocking), "
            "Streamlit (intermediate — data app deployment), "
            "MySQL (intermediate — relational database, used for e-commerce project), "
            "OpenMP (intermediate — CPU parallel programming with shared-memory thread parallelism), "
            "CMake (intermediate — C++ build system, used in HPC project), "
            "Agile (intermediate — software development methodology), JIRA (intermediate — project tracking)."
        ),
        "source": "tool_skills",
        "source_type": "skill",
        "metadata": {"category": "tool"},
    },
    {
        "content": (
            "CUDA (intermediate — NVIDIA GPU parallel programming platform; used for shared memory "
            "optimization, memory coalescing, warp divergence management, and high-performance "
            "kernel design in the HPC CS 759 vector search project). "
            "Also using Thrust and CUB (NVIDIA GPU libraries for parallel sorting, reduction, "
            "and prefix scan), CMake (C++ build system), and Slurm (HPC cluster job scheduling)."
        ),
        "source": "cuda_skills",
        "source_type": "skill",
        "metadata": {"category": "framework"},
    },

    # -----------------------------------------------------------------------
    # PERSONAL BIO
    # -----------------------------------------------------------------------
    {
        "content": (
            "Avyakt Garg — MS CS student at University of Wisconsin-Madison (GPA 4.0), two-time Uber "
            "software engineering intern (AI Solutions in 2024-25, Customer Obsession in Summer 2026), "
            "and currently a UW-Madison teaching assistant for Data Management for Data Science. "
            "Background spans distributed systems engineering (Go, Kafka, gRPC, SpringBoot at Uber), "
            "GPU / HPC programming (CUDA vector search), and machine learning research (graph neural "
            "networks, medical imaging, IoT), plus full-stack AI infrastructure (RAG pipelines). "
            "Originally from New Delhi, India; BITS Pilani dual-degree graduate (CS + Biological Sciences, "
            "GPA 9.01/10). MITACS Globalink Scholar. Currently in Madison, Wisconsin, open to new-grad "
            "software and ML engineering roles for 2027."
        ),
        "source": "personal_bio",
        "source_type": "personal",
        "metadata": {"name": "Avyakt Garg", "location": "Madison, Wisconsin"},
    },
]

# ---------------------------------------------------------------------------
# Embedding generation
# ---------------------------------------------------------------------------

import json as _json
import urllib.error
import urllib.request

# Google Gemini embeddings — free tier ~100 RPM (vs Voyage voyage-3-lite's 3 RPM
# once the trial credit is spent, which is what took the chatbot offline).
# The query side lives in rag-chatbot/internal/rag/embedder.go and MUST stay on
# the same model + dimensionality + task-type pairing.
EMBED_MODEL = "gemini-embedding-001"
EMBED_DIMS = 768
EMBED_URL = (
    f"https://generativelanguage.googleapis.com/v1beta/models/{EMBED_MODEL}:embedContent"
)


def _embed_one(text: str, api_key: str) -> list[float]:
    body = _json.dumps(
        {
            "model": f"models/{EMBED_MODEL}",
            "content": {"parts": [{"text": text}]},
            # Documents are RETRIEVAL_DOCUMENT; the chatbot embeds queries as
            # RETRIEVAL_QUERY. The asymmetry is deliberate and improves recall.
            "taskType": "RETRIEVAL_DOCUMENT",
            "outputDimensionality": EMBED_DIMS,
        }
    ).encode()
    req = urllib.request.Request(
        EMBED_URL,
        data=body,
        headers={"Content-Type": "application/json", "x-goog-api-key": api_key},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            payload = _json.loads(resp.read())
    except urllib.error.HTTPError as e:
        raise SystemExit(f"Gemini embed HTTP {e.code}: {e.read().decode()[:400]}")
    values = payload.get("embedding", {}).get("values")
    if not values:
        raise SystemExit(f"Gemini embed: no values in response: {_json.dumps(payload)[:400]}")
    return values


def generate_embeddings(chunks: list[dict]) -> list[dict]:
    """Generate {EMBED_DIMS}-dim embeddings for all chunks via Google Gemini."""
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("ERROR: GEMINI_API_KEY environment variable is not set.")
        print("  Free key (no card): https://aistudio.google.com/apikey")
        sys.exit(1)

    print(f"Generating embeddings for {len(chunks)} chunks via Gemini {EMBED_MODEL} ({EMBED_DIMS}d)...")
    for i, chunk in enumerate(chunks, 1):
        chunk["embedding"] = _embed_one(chunk["content"], api_key)
        assert len(chunk["embedding"]) == EMBED_DIMS, (
            f"Expected {EMBED_DIMS}-dim vectors, got {len(chunk['embedding'])}"
        )
        if i % 10 == 0 or i == len(chunks):
            print(f"  Embedded {i}/{len(chunks)} chunks")

    return chunks


# ---------------------------------------------------------------------------
# SQL generation
# ---------------------------------------------------------------------------

def format_vector(floats: list[float]) -> str:
    """Format a float list as a pgvector literal: '[0.123, -0.456, ...]'"""
    return "[" + ",".join(f"{v:.8f}" for v in floats) + "]"


def write_sql(chunks: list[dict], output_path: str) -> None:
    """Write seeds/knowledge_base.sql with one INSERT per chunk."""
    lines = [
        "-- Seed: knowledge_base",
        "-- GENERATED FILE — do not edit by hand.",
        "-- Regenerate: python scripts/embed.py",
        "--",
        f"-- Embeddings: Google Gemini {EMBED_MODEL} ({EMBED_DIMS} dimensions, taskType=RETRIEVAL_DOCUMENT)",
        "-- Chunks: " + str(len(chunks)),
        "--",
        "-- Truncate existing rows before re-seeding (vectors are deterministic for",
        "-- fixed input text, but there is no natural conflict key to upsert on).",
        "TRUNCATE TABLE knowledge_base RESTART IDENTITY CASCADE;",
        "",
    ]

    for chunk in chunks:
        content_escaped  = chunk["content"].replace("'", "''")
        source_escaped   = chunk["source"].replace("'", "''")
        metadata_escaped = json.dumps(chunk["metadata"]).replace("'", "''")
        vector_literal   = format_vector(chunk["embedding"])

        lines.append("INSERT INTO knowledge_base (content, source, source_type, metadata, embedding) VALUES")
        lines.append("(")
        lines.append(f"    '{content_escaped}',")
        lines.append(f"    '{source_escaped}',")
        lines.append(f"    '{chunk['source_type']}',")
        lines.append(f"    '{metadata_escaped}'::jsonb,")
        lines.append(f"    '{vector_literal}'::vector")
        lines.append(");")
        lines.append("")

    with open(output_path, "w") as f:
        f.write("\n".join(lines))

    print(f"\nWrote {len(chunks)} rows to {output_path}")
    print(f"File size: {os.path.getsize(output_path) / 1024:.1f} KB")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root  = os.path.dirname(script_dir)
    output_path = os.path.join(repo_root, "seeds", "knowledge_base.sql")

    chunks = generate_embeddings(CHUNKS)
    write_sql(chunks, output_path)

    print("\nNext step:")
    print(f"  psql $NEON_DATABASE_URL -f {output_path}")
