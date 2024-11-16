module Main

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import List;
import Set;
import String;

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

int getLOC_of_unit(Declaration decl) {
    list[loc] locs = [];
    visit (decl) {
            case node n: if (n.src ?) locs += n.src;
    }
    set[tuple[loc, int]] linenrs = {<myloc.top, myloc.begin.line> , <myloc.top, myloc.end.line> | myloc <- locs};
    return(size(linenrs));
}

// list[tuple[loc, int]] getLOC_per_units(list[Declaration] asts) {
//     list[tuple[loc, int]] units = [];
//     for (ast <- asts) {
//         visit (ast) {
//             case  m:\method(_,_,_,_) : println(getLOC_of_unit(m));
//         }
//     }

//     return units;
// }



void codeAnalysisHandler(loc projectLocation) {
    list[Declaration] asts = getASTs(projectLocation);
    int lines_of_code = getLOC(asts);
  //  list[tuple[loc, int]] units = getLOC_per_units(asts); // get lists per unit, store loc as well so that can be traced back which functions are big

    //list[tuple[loc, int]] units = [];
   for (ast <- asts) {
       visit (ast) {
             case  m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl) : println(getLOC_of_unit(m));
      }
    }


    return;
}



// METRIC CALCULATORS
str calculateVolumeMetric(int amountOfLines) {
    if (amountOfLines > 1000) {
        return "--";
    }
    else { return "++"; }
}