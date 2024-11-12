module Main

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import List;
import Set;
import String;

int main(int testArgument=0) {
    println("argument: <testArgument>");

    loc projectLocation = |cwd://testProject0|;
    list[Declaration]  asts = getASTs(projectLocation);

    // println(asts);
    
    // println("Complexity: <getComplexity(asts)>");
    println("Duplicates: <getDuplicatePercentage(asts)>");
    // println("Whitespace <removeWhitespaceAndBlankLines2(asts)> used");
    // getLOC(asts);

    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

// Cyclomatic complexity 
// formula: C = D + 1, where D is the decision points like if, case, while
int getComplexity(list[Declaration] asts) {
    // Decision points 
    int dp = 0;
    visit(asts){
        case \break(): dp += 1;
        case \continue(): dp += 1;
        case \do(_, _): dp += 1;
        case \foreach(_, _, _): dp += 1;
        case \for(_, _, _, _): dp += 1;
        case \for(_, _, _): dp += 1;
        case \if(_, _): dp += 1;
        case \if(_, _, _): dp += 1;
        case \return(_): dp += 1;
        case \return(): dp += 1;
        case \switch(_, _): dp += 1;
        case \case(_): dp += 1;
        case \defaultCase(): dp += 1;
        case \throw(_): dp += 1;
        case \try(_, _): dp += 1;
        case \try(_, _, _): dp += 1;
        case \catch(_, _): dp += 1;
        case \while(_, _): dp += 1;

    }

    // Apply Cyclomatic complexity formula 
    return dp + 1;
}

int getDuplicatePercentage(list[Declaration] asts) {
    // Remove white space and convet ast so each line is a new item in the list
    list[list[str]] allLines = [];
    list[str] noSpace = [];
    int duplicates = 0;
    int count = 0;

    for (Declaration decl <- asts) {
    // Check if source location is known
    // decl.src is the path to the java file, is there is multiple files there will be multiple iterations
        if (decl.src != |unknown:///|) {
            // Retrieve lines of code from the source location and split by line
            list[str] codeLines = split("\n", readFile(decl.src));
            // Remove whitespace from each line and add to result
            // Are these bad for complexity ??
            noSpace += [replaceAll(line, " ", "") | line <- codeLines];
            allLines += [[line | line <- noSpace, line != ""]];
        }
        count +=1;
    }

    // for (list[str] file <- allLines) {

    // }
    int index = 0;
    map[str, str] codeGroups = {};

    while(index < size(allLines) - 6) {
        list[str] linesToAdd = allLines[index + 6];
        
    }

    println("Count <count>");
    println(allLines);
    println(size(allLines));



    return 0;
}


// void getLOC(list[Declaration] asts) {
//     set[int] unique_lines = {};
//     visit(asts) {
//         case Declaration x: {
//             loc location = x.src;
//             unique_lines += location.begin.line;
//             println(location.begin.line);
//         }
//     }
//     println("hi");
//     println(unique_lines);
//     return; //size(lines);
// }