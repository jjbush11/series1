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
    
    int volume = calculateVolumeMetric(largeAST);
    int complex = calculateComplexityMetric(largeAST);
    int unitSize = calculateUnitSizeMetric(largeAST);
    int duplicate = calculateDuplicateMetric(largeAST);

    int analysability = calculateAnalysability(volume, duplicate, unitSize);
    int change = calculateChangeability(complex, duplicate);
    int testability = calculateTestability(complex, unitSize);

    println("Maintainability metrics:");
    println("Volume: " + toString(volume));
    println("Complexity per unit: " + toString(complex));
    println("Unit size: " + toString(unitSize));
    println("Duplicate: " + toString(duplicate));
    println("*****************************************************");
    println("Maintainability scores: ");
    println("Analysability: " + toString(analysability));
    println("Changeability " + toString(change));
    println("Testability " + toString(testability));
    println("*****************************************************");
    println("Maintainability: " + toString(calculateMaintain(analysability, change, testability)));

    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

// Gets the declaration of all units in the project
list[Declaration] getAllUnits(list[Declaration] ast) {
    list[Declaration] units = [];
    visit (ast) {
             case  m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl) : units += [m];
    }

    return units;
}

// Remove all white space and comments from code, except inline comments
list[list[str]] getCleanedCode(list[Declaration] asts) {
    // list[Declaration] asts = getASTs(projectLocation);
    int lines_of_code = getLOC(asts);

    list[list[str]] allLines = create_list_from_lines_map(get_useful_lines_per_file(asts));

    list[list[str]] allLinesNoSpace = [[]];
    for (lines <- allLines) {
        allLinesNoSpace += [[replaceAll(k, " ", "") | k <- lines]];
    }
    list[list[str]] allLinesNoSpaceComment = [[]];
    for (lines <- allLinesNoSpace) {
        allLinesNoSpaceComment += [[k | k <- lines, !startsWith(k, "//")]];
    } 

    return allLinesNoSpaceComment;
}

// Get total lines of code of a declaraiton after removing comments and whitespace
int getTotalLinesOfCode(list[Declaration] asts) {
    int projectSize = 0;
    list[list[str]] allCleanLines = getCleanedCode(asts);
    for (list[str] listOfLines <- allCleanLines){
        projectSize += size(listOfLines);
    }

    return projectSize;
}

// Get individual number of lines of code of a unit
int unitLinesOfCode(Declaration decl) {
    list[Declaration] declList = [decl];
    return getTotalLinesOfCode(declList);
}

// Gets the cyclomatic complexity of a unit 
int getCycloComplexity(Declaration unit) {
    int dp = 0;
        // Decision points 
    visit(unit){
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
    return dp + 1;
}

// Categorize each complexity 
str categorizeComplexity(int cc) {
    if (cc >= 11 && cc <= 20) {
        return "mod";
    } else if (cc >= 21 && cc <= 50) {
        return "high";
    } else if (cc > 50) {
        return "vhigh";
    } else {
        return "low";
    }
}

// Cyclomatic complexity 
// formula: C = D + 1, where D is the decision points like if, case, while
map[str, real] getComplexity(list[Declaration] asts) {
    real totalNumberLines = 0.0 + getTotalLinesOfCode(asts);
    map[str, int] categoryNumbers = ();
    list[Declaration] allUnits = getAllUnits(asts);
    int dp = 0;
    int count = 0;
    for (unit <- allUnits) {
        int unitSize = unitLinesOfCode(unit);
        int cycloComplex = getCycloComplexity(unit);
        str category = categorizeComplexity(cycloComplex);

        // Assign number of lines to each category
        if (category notin categoryNumbers) {
            categoryNumbers[category] = unitSize;
        } else {
            categoryNumbers[category] += unitSize;
        }       
    }

    // Calculate percentages 
    map[str, real] categoryPercents = ();
    for (key <- categoryNumbers) {
        categoryPercents[key] = (categoryNumbers[key]/totalNumberLines) * 100;
    }

    return categoryPercents;
}

real getDuplicatePercentage(list[Declaration] asts) {
    list[list[str]] allLinesClean = getCleanedCode(asts);

    // Declare map that will record all code chunks in the project
    map[str, list[list[str]]] codeGroups = ();
    // Get total lines of clean code in the project
    real totalLinesCount = 0.0 + getTotalLinesOfCode(asts);
    
    int fileNum = 0;
    // This loops through all the files in the project
    while (fileNum < size(allLinesClean)) {
        
        list[str] currentFile = allLinesClean[fileNum];

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


void codeAnalysisHandler(loc projectLocation) {
    list[Declaration] asts = getASTs(projectLocation);
    int lines_of_code = getLOC(asts);
    println(lines_of_code);



    // TESTER FOR PRINTING UNIT SIZES
    for (unit_size <- get_unit_sizes(asts)) {
        println(unit_size);
    }

     list[list[str]] allLines = create_list_from_lines_map(get_useful_lines_per_file(asts));


    return;
}

int getLOC(list[Declaration] asts) {
    list[loc] locs = [];

    visit (asts) {
            case node n: if (n.src ?) locs += n.src;
    }
    set[tuple[loc, int]] linenrs = {<myloc.top, myloc.begin.line> , <myloc.top, myloc.end.line> | myloc <- locs};

    return(size(linenrs) - 1);
}

map[loc, set[int]] get_useful_lines_per_file(list[Declaration] asts) {
    list[loc] locs = [];

    visit (asts) {
            case node n: if (n.src ?) locs += n.src;
    }
    // this creates a map of files, with for every file the lines which actually have code
    map[loc, set[int]] lines_map = ();
    for (myloc <- locs) {
        int begin_line = myloc.begin.line;
        int end_line = myloc.end.line;
        loc key = myloc.top;
        if (key notin lines_map) {
            lines_map[key] = {begin_line, end_line};
        }
        else {
            lines_map[myloc.top] = lines_map[myloc.top] + begin_line + end_line;
        }

    }
    return lines_map;
}

 list[list[str]] create_list_from_lines_map(map[loc, set[int]] lines_map) {
    list[list[str]] allLines = [];
    // 1. loop over map to get all get all files
    set[loc] files = { k | k <- lines_map };
    for (file <- files) {
        list[str] codeLines = split("\n", readFile(file));
       // sort(lines_map(file));

        list[str] actual_code_lines = [codeLines[lineNr-1] | lineNr <- sort(lines_map[file])];
        allLines = allLines + [actual_code_lines];
    }

   return allLines;

}

int getLOC_of_unit(Declaration decl) {
    list[loc] locs = [];
    visit (decl) {
            case node n: if (n.src ?) locs += n.src;
    }
    set[tuple[loc, int]] linenrs = {<myloc.top, myloc.begin.line> , <myloc.top, myloc.end.line> | myloc <- locs};
    return(size(linenrs));
}

 list[int] get_unit_sizes(list[Declaration] asts) {
    list[int] unit_sizes = [];
   for (ast <- asts) {
       visit (ast) {
             case  m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl) : unit_sizes += getLOC_of_unit(m);
      }
    }
    return unit_sizes;
}

// Print scores 
str toString(int number) {
  if (number == 1) {
    return "--";
  } else if (number == 2) {
    return "-";
  } else if (number == 3) {
    return "o";
  } else if (number == 4) {
    return "+";
  } else if (number == 5) {
    return "++";
  } else {
    return "Invalid input";
  }
}

/*
* METRIC CALCULATORS
*/

// VOLUME: Convert (lines of code) LOC into man years 
int calculateVolumeMetric(list[Declaration] asts) {
    int totalLineCount = getLOC(asts);
    int k = 1000;
    if (totalLineCount >= 0 && totalLineCount <= 66 * k) {
        return 5;
    } else if (totalLineCount > 66 * k && totalLineCount <= 246 * k) {
        return 4;
    } else if (totalLineCount > 246 * k && totalLineCount <= 665 * k) {
        return 3;
    } else if (totalLineCount > 665 * k && totalLineCount <= 1310 * k) {
        return 2;
    } else {
        return 1;
    }
}

// UNIT SIZE
int calculateUnitSizeMetric(list[Declaration] asts) {
    list[int] unitSizes = get_unit_sizes(asts);
    real totalNumberLines = 0.0 + getTotalLinesOfCode(asts);
    map[str, int] categoryNumbers = ();
    for (unitSize <- unitSizes) {
        // Get the category of unit size 
        str category = categorizeUnitSize(unitSize);

        // Assign number of lines to each category
        if (category notin categoryNumbers) {
            categoryNumbers[category] = unitSize;
        } else {
            categoryNumbers[category] += unitSize;
        }       
    }

    // Calculate percentages 
    map[str, real] categoryPercents = ();
    for (key <- categoryNumbers) {
        categoryPercents[key] = (categoryNumbers[key]/totalNumberLines) * 100;
    }

    // Add missing categories if neccessary so the next section does not cause errors
    if ("mod" notin categoryPercents) {
        categoryPercents["mod"] = 0.0;
    } 
    if ("high" notin categoryPercents) {
        categoryPercents["high"] = 0.0;
    }
    if ("vhigh" notin categoryPercents) {
        categoryPercents["vhigh"] = 0.0;
    }

    // Categorize based on percent of code in moderate level, high level, and very high level
    if (categoryPercents["mod"] <= 25 && categoryPercents["high"] < 1 && categoryPercents["vhigh"] < 1) {
            return 5;
    } else if (categoryPercents["mod"] <= 30 && categoryPercents["high"] <= 5 && categoryPercents["vhigh"] < 1) {
        return 4;
    } else if (categoryPercents["mod"] <= 40 && categoryPercents["high"] <= 10 && categoryPercents["vhigh"] < 1) {
        return 3;
    } else if (categoryPercents["mod"] <= 50 && categoryPercents["high"] <= 15 && categoryPercents["vhigh"] <= 5) {
        return 2;
    } else {
        return 1;
    }
}

str categorizeUnitSize(int size) {
    if (size >= 0 && size <= 30) {
    return "low";
  } else if (size > 30 && size <= 44) {
    return "mod";
  } else if (size > 44 && size <= 74) {
    return "high";
  } else if (size > 74) {
    return "vhigh";
  } else {
    return "Invalid size"; // Handle negative or invalid input
  }
}

// COMPLEXITY
int calculateComplexityMetric(list[Declaration] asts) {
    map[str, real] categoryPercents = getComplexity(asts);
    // Add missing categories if neccessary so the next section does not cause errors
    if ("mod" notin categoryPercents) {
        categoryPercents["mod"] = 0.0;
    } 
    if ("high" notin categoryPercents) {
        categoryPercents["high"] = 0.0;
    }
    if ("vhigh" notin categoryPercents) {
        categoryPercents["vhigh"] = 0.0;
    }

    // Categorize based on percent of code in moderate level, high level, and very high level
    if (categoryPercents["mod"] <= 25 && categoryPercents["high"] < 1 && categoryPercents["vhigh"] < 1) {
            return 5;
    } else if (categoryPercents["mod"] <= 30 && categoryPercents["high"] <= 5 && categoryPercents["vhigh"] < 1) {
        return 4;
    } else if (categoryPercents["mod"] <= 40 && categoryPercents["high"] <= 10 && categoryPercents["vhigh"] < 1) {
        return 3;
    } else if (categoryPercents["mod"] <= 50 && categoryPercents["high"] <= 15 && categoryPercents["vhigh"] <= 5) {
        return 2;
    } else {
        return 1;
    }
}

// DUPLICATE
int calculateDuplicateMetric(list[Declaration] asts) {
    real duplicatePercent  = getDuplicatePercentage(asts);

    if (duplicatePercent >= 0 && duplicatePercent <= 3) {
        return 5;
    } else if (duplicatePercent > 3 && duplicatePercent <= 5) {
        return 4;
    } else if (duplicatePercent > 5 && duplicatePercent <= 10) {
        return 3;
    } else if (duplicatePercent > 10 && duplicatePercent <= 20) {
        return 2;
    } else {
        return 1;
    }
}

/*
* MAINTABILITY
*/

// ANALYSABILITY 
int calculateAnalysability(int volume, int duplication, int unitSize) {
    return (volume + duplication + unitSize)/3;
}

// CHANGEABILITY  
int calculateChangeability(int complexity, int duplication) {
    return (complexity + duplication)/2;
}

// TESTABILITY 
int calculateTestability(int complexity, int unitSize) {
    return (complexity + unitSize)/2;
}

// MAINTAINABILITY 
int calculateMaintain(int analyse, int change, int testability) {
    return (analyse + change + testability)/3;
}




