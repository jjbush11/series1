module Main

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import List;
import Set;
import String;
import Map;

import List;
import IO;



void main(int testArgument=0) {

    loc projectLocation = |cwd://testProject0|;
    codeAnalysisHandler(projectLocation);
//     for (ast <- asts) {
//         visit (ast) {
//             case  m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl) : println(getLOC_of_unit(m));
//      }
//    }

    return;
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


list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
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
    println(lines_map);
    set[loc] files = { k | <k,_> <- toList(lines_map) };
    for (file <- files) {
        list[str] codeLines = split("\n", readFile(file));
       // sort(lines_map(file));

        list[str] actual_code_lines = [codeLines[lineNr-1] | lineNr <- sort(lines_map[file])];
        //println(sort(lines_map[file]));
        println(actual_code_lines);
        allLines = allLines + [actual_code_lines];
    }

    println(allLines);
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

// METRIC CALCULATORS
str calculateVolumeMetric(int amountOfLines) {
    if (amountOfLines > 1000) {
        return "--";
    }
    else { return "++"; }
}