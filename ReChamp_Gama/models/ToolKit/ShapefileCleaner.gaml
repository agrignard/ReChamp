/***
* Name: ShapefileCleaner
* Author: Tri
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ShapefileCleaner

global {
	//LIGNES A MODIFIER EN FONCTION DES SHAPEFILES:
	// input file
	//output file
	// attributes_to_match
	// create road
	// attributs des routes
	// save road

	string input_file <- "../../includes/GIS/polylines_roads.shp";
	string output_file <- "../../includes/GIS/roads_test.shp";
	list<string> attributes_to_match <- ["lanes","name","other_tags"];

	file roads_shapefile <- file(input_file);
	geometry shape <- envelope(input_file);
	map<point, list<new_road>> vertices <- [];
	list<string> roads_attributes;
	int unmerged_count <- 0;
	
	init {
		create road from: roads_shapefile with: ["OBJECTID"::read("OBJECTID"),"lanes"::read("lanes"),"name"::read("name"),"highway"::read("highway"),"other_tags"::read("other_tags")];		
		roads_attributes <- attributes(first(road)).keys;		
		ask road{
			do split_road;
		}		
		
		ask new_road{
			int index;
			loop p over: shape.points{
				put ((vertices contains_key p)?vertices[p]:[])+self key: p in: vertices;
			} 
		}	
			
		loop p over: vertices.keys{
			if length(vertices[p]) = 2{
				do merge(first(vertices[p]),last(vertices[p]));
			}
		}		
		write ""+unmerged_count+" were not merged because of different attributes."; 

		save road to: output_file with: ["OBJECTID"::"OBJECTID", "lanes"::"lanes","name"::"name"] type: "shp"; // crs: "EPSG:4326"; le crs ne marche pas ??
		write "Cleaning done, output saved to file: "+output_file;
	
	
	}
	
	
	
	action merge(new_road r1, new_road r2){// does not merge two edges if they don't have the same attributes, or are in opposit ways.
	    if attributes_to_match accumulate(get(r1,each)) = attributes_to_match accumulate(get(r2,each)){
			if last(r2.shape.points) = first(r1.shape.points){			
				r2.shape <- polyline(first(length(r2.shape.points)-1,r2.shape.points)  + r1.shape.points);
				vertices[last(r1.shape.points)] <- vertices[last(r1.shape.points)] - r1 + r2;
				ask r1 {do die;}		
			}else if last(r1.shape.points) = first(r2.shape.points){
				r1.shape <- polyline(first(length(r1.shape.points)-1,r1.shape.points)  + r2.shape.points);
				vertices[last(r2.shape.points)] <- vertices[last(r2.shape.points)] - r2 + r1;	
				ask r2 {do die;}
			}
		}else{
			write "Unmerged roads:";
			write ""+r1.name+"-- lane numbers "+r1.lanes+", other_tags: "+r2.other_tags;
			write ""+r2.name+"-- lane numbers "+r2.lanes+", other_tags: "+r2.other_tags+"\n";
			unmerged_count <- unmerged_count + 1;
		}
	}
}




species road  {

	string OBJECTID;
	string lanes;
	string name;
	string highway;
	string other_tags;
	
	rgb color <- rnd_color(255);

	action split_road{
		loop i from:0 to: length(shape.points)-2 {
			create new_road{
				shape <- polyline([myself.shape.points[i],myself.shape.points[i+1]]);
				OBJECTID <- myself.OBJECTID;
				lanes <- myself.lanes;
				name <- myself.name;
				color <- i=0?myself.color:rnd_color(255);
			}
		}
	}
	
	aspect base{	
		draw shape color: color;
	}
}

species new_road  {
	
	string OBJECTID;
	string lanes;
	string name;
	string highway;
	string other_tags;
	
	rgb color <- rnd_color(255);

	aspect base{	
		draw shape color: color;
	}
}


experiment clean type: gui {
	output {
		display Before background:#black {
			species road aspect:base;						
		}
		display after background:#black {
			species new_road aspect:base;						
		}
	}
}