module Main

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import List;
import Set;
import String;

int main(int testArgument=0) {
    println("argument: <testArgument>");

    // Test java project
    loc testJavaProject = |cwd://testProject0|;
    list[Declaration]  javaAST = getASTs(testJavaProject);
    
    // Small SQL project
    // loc smallSQL = |project://SQLproject/smallsql0.21_src|;
    // list[Declaration]  smallAST = getASTs(smallSQL);

    // // Large SQL prioject 
    // loc largeSQL = |project://SQLbigProject/hsqldb-2.3.1|;
    // list[Declaration]  largeAST = getASTs(largeSQL);

    // println(asts);
    
    // println("Complexity: <getComplexity(asts)>");
    println("Percentage of duplicates in java: <getDuplicatePercentage(javaAST)>");
    // println("Percentage of duplicates in small: <getDuplicatePercentage(smallAST)>");
    // println("Percentage of duplicates in large: <getDuplicatePercentage(largeAST)>");

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

list[str] removeInlineComments(list[str] lines) {
    return visit(lines) {
        case str line => replaceAll(line, /\s*\/\/.*$/, "")
    }
}

real getDuplicatePercentage(list[Declaration] asts) {
    list[list[str]] allLines = [];

    for (Declaration decl <- asts) {
    // Check if source location is known
    // decl.src is the path to the java file, is there is multiple files there will be multiple iterations
    list[str] noSpace = [];
    list[str] noCommentSpace = [];
        if (decl.src != |unknown:///|) {
            // Retrieve lines of code from the source location and split by line
            list[str] codeLines = split("\n", readFile(decl.src));
            // Remove inline comments
            codeLines = [replaceAll(line, "\\s*//.*$", "") | line <- codeLines];

            // Remove multiline comments
            codeLines = [replaceAll(line, "/\\*.*?\\*/", "") | line <- codeLines];

            // Remove whitespace from each line and add to result
            noSpace += [replaceAll(line, " ", "") | line <- codeLines];
            noCommentSpace += [line | line <- noSpace, !contains(line, "//")];
            allLines += [[line | line <- noSpace, line != ""]];
        }
    }

    // Declare map that will record all code chunks in the project
    map[str, list[list[str]]] codeGroups = ();
    real totalLinesCount = 0.0;
    
    int fileNum = 0;
    // This loops through all the files in the project
    while (fileNum < size(allLines)) {
        
        list[str] currentFile = allLines[fileNum];

        // Find the total number of lines in the project
        totalLinesCount += size(currentFile);

        // If file is smaller than 6 lines ignore it
        // Index is also the line number in the file 
        int index = 0;
        while(index <= size(currentFile) - 6) {
            // Take 6 lines of code from the file 
            list[str] linesToAdd = currentFile[index..index + 6];

            // Combine to be one string instead of 6 seperate strings to use for hash key
            str linesToAddStr = "";
            for (str line <- linesToAdd) {
                linesToAddStr += line;
            }
            
            str key = md5Hash(linesToAddStr);
            int lineNum = index + 1;
            list[str] linesToAddFinal = [];

            // Giving each line a file ID and line number to make them unique 
            for (str line <- linesToAdd){
                linesToAddFinal += "<line> (src: <fileNum>, lineNum: <lineNum>)" + line;
                lineNum += 1;
            }
            // Check if code chunck is already in map, if not add it, if yes append to list at the key
            if (key notin codeGroups) {
                codeGroups[key] = [linesToAddFinal]; //[[ "<line> (src: <fileNum>, lineNum: <index + 1>)" | line <- linesToAdd ]];

            } else {
                codeGroups[key] += [linesToAddFinal]; // [[ "<line> (src: <fileNum>, lineNum: <index + 1>)" | line <- linesToAdd ]];
            }
            index += 1;
        }
        fileNum += 1;
    }

    // The code group is a duplicate if the list found at codeGroup[key] has more than one item
    map[str, list[list[str]]] duplicateGroups = (key : codeGroups[key] | key <- codeGroups, size(key) > 1);

    set[str] duplicateLines = {};
    // Extract the individual lines from the duplicate chuncks of code 
    for (str key <- codeGroups) {
        if (size(codeGroups[key]) > 1) {
            for (list[str] lines <- codeGroups[key]) {
                for (str line <- lines) {
                    duplicateLines += line;
                }
            }
        }
    }

    println("Nuber of duplicates: <size(duplicateLines)>");
    return ((size(duplicateLines))/totalLinesCount) * 100;
}




