import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DiffresultComponent } from './diffresult.component';

describe('DiffresultComponent', () => {
  let component: DiffresultComponent;
  let fixture: ComponentFixture<DiffresultComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ DiffresultComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(DiffresultComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
