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

    println(asts);
    
    // println("Complexity: <getComplexity(asts)>");
    // println("Duplicates: <getDuplicatePercentage(asts)>");
    // println("Whitespace <removeWhitespaceAndBlankLines2(asts)> used");
    removeWhitespaceAndBlankLines(asts);
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
    list[Declaration] filteredAst = removeWhitespaceAndBlankLines(asts);

    // Form grouping 
    set[str] codeGroups = {};
    int duplicates = 0;

    visit(asts) {
        case Declaration x: {
            if (x.src != |unknown:///|) {
                loc location = x.src;
                // unique_lines += location.begin.line;
                // println(x.src.begin.line);
                // println(location.end.line);
                // int start = location.begin.line;
                int end = location.end.line;
                for(int n <- [1 .. end]) {
                    // lines += |location.file|[line];
                    println(n);
                }
            }
           
        }
    }

    // int numLines = 6;

    

    
    return 0;
}

list[Declaration] removeWhitespaceAndBlankLines(list[Declaration] asts) {
    list[Declaration] filteredASTs = [];
    int count = 0;
    
    visit(asts) {
        case Declaration x: {
            loc location = x.src;
            if (location != |unknown:///|) {
                // Check if the line is not blank or whitespace
                if (!isBlankOrWhitespace(location)) {
                    filteredASTs += x;
                } else {
                    count += 1;
                }
            }
        }
    }
    println("USed count <count>");
    return filteredASTs;
}

int removeWhitespaceAndBlankLines2(list[Declaration] asts) {
    list[Declaration] filteredASTs = [];
    int count = 0;
    visit(asts) {
        case /[\t\n]/: count += 1;
        // case /[" "]/: count+=1;
    }
    
    return count;
}

bool isBlankOrWhitespace(loc location) {
    // Read the content of the location
    str content = readFile(location);
    // Check if the content is blank or contains only whitespace
    return content == "" || content == " " || content == "\t" || content == "\n" || content == "\r\n";
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