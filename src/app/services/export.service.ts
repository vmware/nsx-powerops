import { Injectable } from '@angular/core';
import { Workbook } from 'exceljs';
import * as fs from 'file-saver';
import * as JSZip from 'jszip';
import * as  YAML from 'js-yaml'


@Injectable({
  providedIn: 'root'
})
export class ExportService {
  constructor() { }

  public createZIPFile(data: Array<any>, extension: string){
    let zipfile = this.createFilename('Audit','zip')
    const jszip = new JSZip();
    for ( let item of data){
      let filecontent: any
      switch(extension){
        case 'CSV': {
          filecontent = this.generateCSV(item.name, item.header, item.data, false)
          break
        }
        case 'JSON': {
          filecontent = JSON.stringify(item.data, null, " ");
          break
        }
        case 'YAML': {
          filecontent = YAML.dump(item.data, {sortKeys: true, noRefs: true, forceQuotes: true})
          break
        }
      }
      jszip.file(item.name + '.' + extension.toLowerCase(), filecontent);

    }

    jszip.generateAsync({ type: 'blob' }).then(function(content) {
      // see FileSaver.js
      saveAs(content, zipfile);
    });
  }

  public generateExcel(element: string, datasheet: any, formatting?: any ){
    let WB = new Workbook();
    for (let sheet of datasheet){
      let sheetdone = false
      // Get Formating information : if Array, it's a call from Audit Page, else call form Menus
      if(Array.isArray(formatting)){
          for(let formatsheet of formatting){
            if(formatsheet && sheet.name === formatsheet.sheet ){
              WB = this.FillSheet(WB, sheet.name, sheet.header, sheet.data, formatsheet.column)
              sheetdone = true
            }
          }
          if(!sheetdone){
            WB = this.FillSheet(WB, sheet.name, sheet.header, sheet.data)
          }
      }
      else if (formatting){
        WB = this.FillSheet(WB, sheet.name, sheet.header, sheet.data, formatting.column)
      }
      else{
        WB = this.FillSheet(WB, sheet.name, sheet.header, sheet.data)
      }
    }
     // Write File
    WB.xlsx.writeBuffer().then((tab: BlobPart) => {
      let blob = new Blob([tab], {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'});
      let filename = this.createFilename(element, 'xlsx')
      fs.saveAs(blob, filename)
    });
    }
  
  FillSheet(wb: any, nameTab: string, header: Array<any>, Exceldata: Array<any>, formatting?: any){
    let WS = wb.addWorksheet(nameTab);
    let columsHeader: any[] = []
    let rowTable: any[] = []

    let ConditionalColor = {
      red: {
        fill: { pattern: 'solid', type: 'pattern', bgColor: {argb: 'FFC7CE'}},
        // font: { italic:true, size: 18, color: {argb: '9C0103' }}
        },
      green: {
        fill: { pattern: 'solid', type: 'pattern', bgColor: {argb: 'C6EFCE'}},
        // font: { color: {argb:'006100' }},
        },
      orange: {
        fill: { pattern: 'solid', type: 'pattern', bgColor: {argb: 'FFEB9C'}},
        // font: { color: { argb: '9C5700' }}
      }
    }


    for (let head of header){
      columsHeader.push({
        'name': head, 
        'filterButton': true
      })
    }

    // case if data is empty. Fill with one line
    if (Exceldata.length === 0){
      // let nbcolumn = header.length
      for(let nb of header){
        Exceldata.push("no data")
      }
      rowTable.push(Object.values(Exceldata)) 
    }
    else{
      for (let line of Exceldata){ 
        rowTable.push(Object.values(line)) 
      }
    }
    // Create Excel Table
    WS.addTable(
      {
        name: nameTab,
        ref: 'A1',
        headerRow: true,
        style: {
        theme: 'TableStyleLight9',
        showRowStripes: true
        },
        columns: columsHeader,
        rows: rowTable
      }
    );
    // Conditionnal Formatting
    if(formatting && formatting.length >0){
      let conditionnalFTInfo: any
      for (let col of formatting){
        // get letter of IndexColumn
        let LetterColumn = String.fromCharCode(96 + col.columnIndex).toUpperCase();
        // Construct conditionnal informations
        let rules: any[] = []
        for( let rule of col.rules){
          rules.push({
            type: 'containsText',
            operator: 'containsText',
            text: rule.text,
            style: ConditionalColor[rule.color],
          })
        }
        conditionnalFTInfo = {
          ref: LetterColumn + '2:' + LetterColumn + (rowTable.length + 1).toString(),
          rules: rules
        }
        WS.addConditionalFormatting(conditionnalFTInfo)  
      }
    }


    return wb
  }


  public FormatTab(Tab: any, Header: any, separator: any, diff: boolean){
    let Tabline = []

    for (let item of Tab){
      let line: any = {}
      if(diff){
        line =  { 'DiffStatus': item.diffstatus }
      }
      for (let column of Header){
        // Array value
        if (Array.isArray(item[column.col])){
            let elementtab = []
           for (let subitem of item[column.col]){
             if (typeof(subitem) != 'object'){
               elementtab.push(subitem)
             }
             else{
              elementtab.push(subitem[column.subcol])
             }
           }
           line[column.header] = elementtab.join(separator)
         }
        // Normal value
        else if (typeof(item[column.col]) != 'object'){
          line[column.header] = item[column.col]
        }
        // Object Value
        else if(typeof(item[column.col]) == 'object'){
          line[column.header] = item[column.col][column.subcol]
        }
      }
      Tabline.push(line)
    }
    return Tabline
  }

  /*
  public Export(type: string, Tab:any, PrefixName: any, Header: any, diff: boolean){
    let Export: any
    // Construct list of header for csv and xls
    if(diff){
      let HeaderCol = ['DiffStatus']
      for (let header of Header){
        HeaderCol.push(header.header)
      }
      Header = HeaderCol
    }

    switch(type){
      case 'XLS': {
        Export = this.FormatTab(Tab, Header, ', ', diff)
        this.generateExcel(PrefixName, Header, Export)
        break;
      }
      case 'CSV': {
        Export = this.FormatTab(Tab, Header,'/', diff)
        this.generateCSV(PrefixName, Header, Export, true)
        break;
      }
      case 'JSON': {
        this.generateJSON(PrefixName, Tab)
        break;
      }
      case 'YAML': {
        this.generateYAML(PrefixName, Tab)
        break;
      }
    }
  }
*/

  public generateJSON(filenamestr: string, Tab: any) {
    let filename = this.createFilename(filenamestr, 'json')
    let theJSON = JSON.stringify(Tab, null, " ");
    this.saveFile(filename, theJSON, "data:application/json;charset=UTF-8,")
  }

  public generateYAML(filenamestr: string, Tab: any) {
    let filename = this.createFilename(filenamestr, 'yaml')
    let yamlstr = YAML.dump(Tab, {sortKeys: true, noRefs: true, forceQuotes: true})
    this.saveFile(filename, yamlstr, "data:application/yaml;charset=UTF-8,")
  }

  public generateCSV(element: string, headers: Array<any>, rows: Array<any>, save: boolean){
    if (!rows || !rows.length) {
      return null;
    }
    const separator: string = ",";
    const keys: string[]  = Object.keys(rows[0]);

    let columHearders: string[];

    if (headers) {
      columHearders = headers;
    } else {
      columHearders = keys;
    }

  const csvContent =
      columHearders.join(separator) +
      '\n' +
      rows.map(row => {
          return keys.map(k => {
              let cell = row[k] === null || row[k] === undefined ? '' : row[k];

              cell = cell instanceof Date 
                  ? cell.toLocaleString()
                  : cell.toString().replace(/"/g, '""');

              if (cell.search(/("|,|\n)/g) >= 0) {
                  cell = `"${cell}"`;
              }
              return cell;
          }).join(separator);
      }).join('\n');

    if (save){
      let filename = this.createFilename(element, 'csv')
      this.saveFile(filename, csvContent,'text/csv;charset=utf-8;')
      return null
    }
    else{
      return csvContent
    }
  }

  saveFile(filename: string, Element: any, type: any){
    const blob = new Blob([Element], { type: type });
    if (navigator.msSaveBlob) { // In case of IE 10+
        navigator.msSaveBlob(blob, filename);
    } 
    else {
        const link = document.createElement('a');
        if (link.download !== undefined) {
            // Browsers that support HTML5 download attribute
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', filename);
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
      }
  }

  addZero(i) {
    if (i < 10) {
      i = "0" + i;
    }
    return i;
  }

  createFilename(file: string, extension: string): string { 
    var d = new Date(); 
    var mo = this.addZero(d.getMonth() + 1); 
    var yr = this.addZero(d.getFullYear()); 
    var dt = this.addZero(d.getDate()); 
    var h = this.addZero(d.getHours()); 
    var m = this.addZero(d.getMinutes()); 
    var s = this.addZero(d.getSeconds()); 

    return (file + "_" + yr  + mo + dt + '-' + h  + m  + s + '.' + extension); 
  }

}
