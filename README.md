# BCS24 – Compiler Design Project

A compiler implementation for the BCS24 programming language using **Flex and Bison**. This project focuses on lexical analysis and syntax analysis to validate programs based on the language grammar.

## Overview

BCS24 is a simple programming language that supports variable declarations, assignments, arithmetic expressions, conditional statements, and looping constructs.

The compiler performs two major phases:

- **Lexical Analysis:** Identifies tokens such as keywords, identifiers, operators, and constants using Flex.
- **Syntax Analysis:** Checks whether the sequence of tokens follows the grammar of BCS24 using Bison.

The current implementation focuses on syntax validation.

## Features

- Supports `int` and `bool` variable declarations.
- Supports variable assignments.
- Handles arithmetic expressions.
- Supports `if-else` conditional statements.
- Supports `while` loops.
- Detects invalid syntax.
- Provides parsing success or syntax error messages.

## Tech Stack

- **C** – Implementation language
- **Flex** – Lexical analyzer generator
- **Bison** – Parser generator
- **GCC** – C compiler
- **Makefile** – Build automation

## Project Structure

```text
BCS24/
│
├── lexer.l              # Lexical analyzer rules
├── parser.y             # Grammar and parsing rules
├── Makefile             # Build instructions
├── tests/
│   ├── test1.bcs        # Valid test case
│   ├── test2.bcs        # Valid test case
│   ├── test3.bcs        # Valid test case
│   ├── error1.bcs       # Invalid test case
│   ├── error2.bcs       # Invalid test case
│   └── error3.bcs       # Invalid test case
│
└── bcs24.exe            # Generated executable
```

## Grammar Overview

The main program follows this structure:

```text
BcsMain {
    declist
    stmtlist
}
```

The language follows these basic rules:

1. Variable declarations must appear before statements.
2. Variables can be declared using `int` and `bool`.
3. Assignments support arithmetic expressions.
4. Conditional execution is supported through `if-else`.
5. Repetitive execution is supported through `while` loops.

## Getting Started

### Prerequisites

Make sure the following tools are installed:

- GCC
- Flex
- Bison
- Make

### Build the Project

Run the following command in the project directory:

```bash
make
```

The Makefile performs the following steps:

1. Generates parser files using Bison.
2. Generates lexical analyzer code using Flex.
3. Compiles the generated C files using GCC.
4. Produces the executable `bcs24.exe`.

### Run the Compiler

Run the executable with an input file:

```bash
.\bcs24.exe < tests/test1.bcs
```

You can also test other input files:

```bash
.\bcs24.exe < tests/test2.bcs
.\bcs24.exe < tests/test3.bcs
```

### Test Invalid Programs

```bash
.\bcs24.exe < tests/error1.bcs
.\bcs24.exe < tests/error2.bcs
.\bcs24.exe < tests/error3.bcs
```

## Expected Output

For a syntactically valid program:

```text
Parsing Successful
```

For a program containing syntax errors:

```text
Syntax Error
```

## Current Scope

This implementation focuses on lexical and syntax analysis.

It validates whether a program follows the defined BCS24 grammar. Semantic analysis, such as checking whether variables have been declared before use, is outside the scope of the current implementation.

## Learning Outcomes

- Understanding compiler architecture.
- Implementing lexical analysis using Flex.
- Designing context-free grammars using Bison.
- Understanding tokenization and parsing.
- Handling syntax errors.
- Integrating generated C code with GCC.

---

**Developed as part of the Compiler Design coursework.**
