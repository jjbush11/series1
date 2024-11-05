module Main

import IO;
import lang::java::m3::Core;
import lang::java::m3::AST;
import List;
import Set;
import String;

int main(int testArgument=0) {
    println("argument: <testArgument>");
    // Example projedt location
    loc projectLocation = |project://SQLproject/smallsql0.21_src|;
    list[Declaration]  asts = getASTs(projectLocation);
    // println("ASTs: <asts>);
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int getNumberOfInterfaces(list[Declaration] asts){
    int interfaces = 0;
    visit(asts){
        case \interface(_, _, _, _): interfaces += 1;
    }
    return interfaces;
}
