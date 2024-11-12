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
    loc smallSQL = |project://SQLproject/smallsql0.21_src|;
    list[Declaration]  smallAST = getASTs(smallSQL);

    // Large SQL prioject 
    loc largeSQL = |project://SQLbigProject/hsqldb-2.3.1|;
    list[Declaration]  largeAST = getASTs(largeSQL);

    // println(asts);
    
    // println("Complexity: <getComplexity(asts)>");
    println("Percentage of duplicates in java: <getDuplicatePercentage(javaAST)>");
    println("Percentage of duplicates in small: <getDuplicatePercentage(smallAST)>");
    println("Percentage of duplicates in large: <getDuplicatePercentage(largeAST)>");
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

real getDuplicatePercentage(list[Declaration] asts) {
    list[list[str]] allLines = [];
    real duplicates = 0.0;
    int count = 0;

    for (Declaration decl <- asts) {
    // Check if source location is known
    // decl.src is the path to the java file, is there is multiple files there will be multiple iterations\
    list[str] noSpace = [];
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

    
    map[str, str] codeGroups = ();
    real totalLinesCount = 0.0;
    
    for (list[str] file <- allLines) {
        // Find the total number of lines in the project
        totalLinesCount += size(file);

        // If file file is smaller than 6 lines ignore it
        int index = 0;
        while(index <= size(file) - 6) {
            // Take 6 lines of code from the file 
            list[str] linesToAdd = file[index..index + 6];

            // Combine to be one string instead of 6 seperate strings
            str linesToAddStr = "";
            for (str line <- linesToAdd) {
                linesToAddStr += line;
            }

            // Check if code chunck is already in map, if not add, if yes increment duplicates
            str key = md5Hash(linesToAddStr);
            if (key in codeGroups) {
                // Increment duplicates
                duplicates += 1;
                // Add to list
                codeGroups[key] += linesToAddStr;
                duplicates += 1;

            } else {
                codeGroups[key] = linesToAddStr;
            }

            index += 1;
        }
    }
    

    // println("Count <count>");
    // println(allLines);
    // println(size(allLines));

    // println(codeGroups);


    println("Nuber of duplicates: <duplicates>");
    return (duplicates/totalLinesCount) * 100;
}