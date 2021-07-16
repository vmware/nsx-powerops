import { ComponentFixture, TestBed } from '@angular/core/testing';

import { RoutingtablesComponent } from './routingtables.component';

describe('RoutingtablesComponent', () => {
  let component: RoutingtablesComponent;
  let fixture: ComponentFixture<RoutingtablesComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ RoutingtablesComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(RoutingtablesComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
